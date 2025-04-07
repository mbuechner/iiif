/*
 * Copyright 2023-2025 Michael Büchner, Deutsche Digitale Bibliothek
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package de.ddb.labs.iiif;

import jakarta.servlet.http.HttpServletRequest;
import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;
import java.util.concurrent.TimeUnit;
import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathExpression;
import javax.xml.xpath.XPathExpressionException;
import javax.xml.xpath.XPathFactory;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.xpath.XPathFactoryImpl;
import okhttp3.Dispatcher;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*", maxAge = 3600)
@Slf4j
class IiifRestController {

    private final static String DDB_API_PROD = "https://api.deutsche-digitale-bibliothek.de/items/";
    private final static String DDB_API_Q1 = "https://api-q1.deutsche-digitale-bibliothek.de/items/";
    private final static String DDB_API_Q2 = "https://api-q2.deutsche-digitale-bibliothek.de/items/";
    private final static String API_KEY = "?oauth_consumer_key=";

    private final Logger LOG = LoggerFactory.getLogger(IiifRestController.class);
    private final OkHttpClient httpClient;
    private final DocumentBuilder db;
    private final XPathExpression checkExpr, recordExpr, oaiRecord, providerIdExpr;
    private final TransformerFactory factory;

    @Value("${iiif.baseurl}")
    private String baseUrl;

    @Value("${iiif.ddb_api_key_prod}")
    private String ddbApiKeyProd;

    @Value("${iiif.ddb_api_key_q1}")
    private String ddbApiKeyQ1;

    @Value("${iiif.ddb_api_key_q2}")
    private String ddbApiKeyQ2;

    @Value("classpath:xslt/cortex-to-iiif.xsl")
    private Resource cortexToIiif;
    private Templates templatesCortexToIiif;

    @Value("classpath:xslt/xml-to-json.xsl")
    private Resource xmlToJson;
    private Templates templatesXmlToJson;

    @Value("classpath:xslt/metsmods-to-iiif.xsl")
    private Resource metsmodsToIiif;
    private Templates templatesMetsmodsToIiif;

    public IiifRestController() throws URISyntaxException, IOException, ParserConfigurationException, XPathExpressionException {
        final Dispatcher dispatcher = new Dispatcher();
        dispatcher.setMaxRequests(64);
        dispatcher.setMaxRequestsPerHost(8);
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(5, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .dispatcher(dispatcher)
                .build();

        factory = new net.sf.saxon.TransformerFactoryImpl();
        // URIResolver setzen
        factory.setURIResolver(new CustomResolver());

        // XML-Dokument parsen
        final DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        dbf.setNamespaceAware(true);
        db = dbf.newDocumentBuilder();

        // XPath-Factory und Kontext mit Präfixen
        final XPathFactory xpf = new XPathFactoryImpl();
        final XPath xpath;
        xpath = xpf.newXPath();
        xpath.setNamespaceContext(new NamespaceContext() {
            @Override
            public String getNamespaceURI(String prefix) {
                return switch (prefix) {
                    case "cortex" ->
                        "http://www.deutsche-digitale-bibliothek.de/cortex";
                    case "ns14" ->
                        "http://www.deutsche-digitale-bibliothek.de/ns/cortex-item-source";
                    case "oai" ->
                        "http://www.openarchives.org/OAI/2.0/";
                    default ->
                        XMLConstants.NULL_NS_URI;
                };
            }

            @Override
            public String getPrefix(String namespaceURI) {
                throw new UnsupportedOperationException();
            }

            @Override
            public Iterator<String> getPrefixes(String namespaceURI) {
                throw new UnsupportedOperationException();
            }
        });

        checkExpr = xpath.compile("/cortex:cortex/ns14:source/ns14:record/@type");
        recordExpr = xpath.compile("/cortex:cortex/ns14:source/ns14:record");
        oaiRecord = xpath.compile("/oai:record/oai:metadata");
        providerIdExpr = xpath.compile("/cortex:cortex/cortex:provider-info/cortex:provider-ddb-id");
    }

    @EventListener(ApplicationReadyEvent.class)
    public void doSomethingAfterStartup() throws TransformerConfigurationException, IOException {

        final StreamSource ss01 = new StreamSource(cortexToIiif.getInputStream());
        final StreamSource ss02 = new StreamSource(xmlToJson.getInputStream());
        final StreamSource ss03 = new StreamSource(metsmodsToIiif.getInputStream());

        templatesCortexToIiif = factory.newTemplates(ss01);
        templatesXmlToJson = factory.newTemplates(ss02);
        templatesMetsmodsToIiif = factory.newTemplates(ss03);
    }

    public Document maybeReplaceWithMetadata(Document doc) throws Exception {

        // <metadata> finden
        final Node metadataNode = (Node) oaiRecord.evaluate(doc, XPathConstants.NODE);

        if (metadataNode != null && metadataNode.hasChildNodes()) {
            // Ersten Inhalt (z. B. <newroot>) aus <metadata> holen
            Node newContent = null;
            for (int i = 0; i < metadataNode.getChildNodes().getLength(); i++) {
                Node child = metadataNode.getChildNodes().item(i);
                if (child.getNodeType() == Node.ELEMENT_NODE) {
                    newContent = child;
                    break;
                }
            }

            if (newContent != null) {
                // Neues leeres Dokument bauen
                Document newDoc = db.newDocument();

                // Element importieren und als Wurzel setzen
                Node imported = newDoc.importNode(newContent, true);
                newDoc.appendChild(imported);

                return newDoc;
            }
        }

        // Keine <metadata> oder leer → Original-Dokument zurückgeben
        return doc;
    }

    @RequestMapping(
            method = RequestMethod.GET,
            produces = "application/json",
            value = "/{id}"
    )
    @ResponseBody
    public ResponseEntity<String> getResource(HttpServletRequest request, @PathVariable String id, @RequestParam(value = "system", required = false) String system) throws FileNotFoundException, IOException, TransformerConfigurationException, TransformerException, SAXException, XPathExpressionException, Exception {

        String requestUrl;

        if (system != null && system.equalsIgnoreCase("Q1")) {
            requestUrl = DDB_API_Q1 + id + API_KEY + ddbApiKeyQ1;
        } else if (system != null && system.equalsIgnoreCase("Q2")) {
            requestUrl = DDB_API_Q2 + id + API_KEY + ddbApiKeyQ2;
        } else {
            requestUrl = DDB_API_PROD + id + API_KEY + ddbApiKeyProd;
        }

        final Request getRequest = new Request.Builder()
                .url(requestUrl)
                .addHeader("Accept", "application/xml")
                .get()
                .build();

        try (final Response response = httpClient.newCall(getRequest).execute()) {
            if (response.isSuccessful()) {

                final String inputXmlString = response.body().string();
                final Document doc = db.parse(new InputSource(new StringReader(inputXmlString)));

                final String typeValue = (String) checkExpr.evaluate(doc, XPathConstants.STRING);
                final String queryParameter = request.getQueryString();

                if ("http://www.loc.gov/METS/".equalsIgnoreCase(typeValue)) {
                    LOG.info("METS-Typ erkannt – Transformation startet...");
                    final String providerId = (String) providerIdExpr.evaluate(doc, XPathConstants.STRING);

                    // Maskierten Inhalt extrahieren                   
                    final Element recordElement = (Element) recordExpr.evaluate(doc, XPathConstants.NODE);
                    final String maskedXml = recordElement.getTextContent().trim();

                    // Inhalt demaskieren: als neues DOM laden
                    Document metsDoc = db.parse(new ByteArrayInputStream(maskedXml.getBytes(StandardCharsets.UTF_8)));
                    metsDoc = maybeReplaceWithMetadata(metsDoc);

                    // Transformation
                    final StringWriter writer = new StringWriter();
                    final StreamResult result = new StreamResult(writer);

                    final Transformer transformer01 = templatesMetsmodsToIiif.newTransformer();
                    transformer01.setParameter("id", request.getRequestURI());
                    transformer01.setParameter("uri", baseUrl + request.getRequestURI() + ((queryParameter == null || queryParameter.isBlank()) ? "" : "?" + queryParameter));
                    transformer01.setParameter("providerId", providerId);

                    transformer01.transform(new DOMSource(metsDoc), result);

                    return ResponseEntity
                            .ok()
                            .header("Content-Type", "application/json")
                            .body(writer.toString());
                } else {

                    LOG.info("Kein METS-Typ erkannt – Transformation startet...");
                    final StringWriter writer = new StringWriter();
                    final StreamResult result = new StreamResult(writer);

                    final Transformer transformer01 = templatesCortexToIiif.newTransformer();
                    transformer01.setParameter("uri", baseUrl + request.getRequestURI() + ((queryParameter == null || queryParameter.isBlank()) ? "" : "?" + queryParameter));

                    final TransformerHandler transformer02 = ((SAXTransformerFactory) factory).newTransformerHandler(templatesXmlToJson);
                    transformer02.setResult(result);

                    transformer01.transform(new StreamSource(new StringReader(inputXmlString)), new SAXResult(transformer02));

                    return ResponseEntity
                            .ok()
                            .header("Content-Type", "application/json")
                            .body(writer.toString());
                }
            }
            
            return ResponseEntity
                    .status(HttpStatusCode.valueOf(404))
                    .header("Content-Type", "application/json")
                    .body("{ \"Error\": \"" + id + " is not a valid DDB id\" }");
        }
    }
}
