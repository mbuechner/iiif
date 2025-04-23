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
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.concurrent.TimeUnit;
import javax.xml.transform.stream.StreamSource;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.s9api.DocumentBuilder;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XPathCompiler;
import net.sf.saxon.s9api.XPathExecutable;
import net.sf.saxon.s9api.XPathSelector;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmDestination;
import net.sf.saxon.s9api.XdmItem;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XdmNodeKind;
import net.sf.saxon.s9api.XsltCompiler;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.XsltTransformer;
import okhttp3.Dispatcher;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import org.apache.commons.text.StringEscapeUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;

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
    private final Processor processor;
    private final DocumentBuilder db;
    private final XsltCompiler compiler;
    private final XPathExecutable checkExpr, recordExpr, oaiRecord, providerInfoExpr;

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
    private XsltExecutable templatesCortexToIiif;

    @Value("classpath:xslt/xml-to-json.xsl")
    private Resource xmlToJson;
    private XsltExecutable templatesXmlToJson;

    @Value("classpath:xslt/metsmods-to-iiif.xsl")
    private Resource metsmodsToIiif;
    private XsltExecutable templatesMetsmodsToIiif;

    // Formatter mit deutschem Stil: Komma als Dezimaltrennzeichen
    final DecimalFormatSymbols symbols;
    final DecimalFormat df;

    public IiifRestController() throws URISyntaxException, IOException, SaxonApiException {
        final Dispatcher dispatcher = new Dispatcher();
        dispatcher.setMaxRequests(64);
        dispatcher.setMaxRequestsPerHost(8);
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(5, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .dispatcher(dispatcher)
                .build();

        processor = new Processor(true); // XSLT 3.0 fähig
        compiler = processor.newXsltCompiler();

        // XML-Dokument parsen
        db = processor.newDocumentBuilder();

        // XPath-Factory und Kontext mit Präfixen
        final XPathCompiler xpath = processor.newXPathCompiler();
        xpath.declareNamespace("cortex", "http://www.deutsche-digitale-bibliothek.de/cortex");
        xpath.declareNamespace("source", "http://www.deutsche-digitale-bibliothek.de/ns/cortex-item-source");
        xpath.declareNamespace("oai", "http://www.openarchives.org/OAI/2.0/");

        checkExpr = xpath.compile("/cortex:cortex/source:source/source:record/@type");
        recordExpr = xpath.compile("/cortex:cortex/source:source/source:record");
        oaiRecord = xpath.compile("/oai:record/oai:metadata");
        providerInfoExpr = xpath.compile("/cortex:cortex/cortex:provider-info");

        symbols = new DecimalFormatSymbols(Locale.GERMANY);
        df = new DecimalFormat("#,##0.000", symbols);
    }

    @EventListener(ApplicationReadyEvent.class)
    public void doSomethingAfterStartup() throws IOException, SaxonApiException {

        final StreamSource ss01 = new StreamSource(cortexToIiif.getInputStream());
        final StreamSource ss02 = new StreamSource(xmlToJson.getInputStream());
        final StreamSource ss03 = new StreamSource(metsmodsToIiif.getInputStream());

        templatesCortexToIiif = compiler.compile(ss01);
        templatesXmlToJson = compiler.compile(ss02);
        templatesMetsmodsToIiif = compiler.compile(ss03);
    }

    public XdmNode maybeReplaceWithMetadata(XdmNode docNode) throws SaxonApiException {

        // XPath anwenden
        XPathSelector selector = oaiRecord.load();
        selector.setContextItem(docNode);
        XdmItem metadataItem = selector.evaluateSingle();

        if (metadataItem instanceof XdmNode metadataNode) {
            for (XdmNode child : metadataNode.children()) {
                if (child.getNodeKind() == XdmNodeKind.ELEMENT) {
                    // Ersten Element-Child gefunden → als neues Dokument zurückgeben
                    return db.build(new StreamSource(new StringReader(child.toString())));
                }
            }
        }

        // Kein <oai:metadata> oder keine Kindelemente → Original zurück
        return docNode;
    }

    @RequestMapping(
            method = RequestMethod.GET,
            produces = "application/json",
            value = "/{id}"
    )
    @ResponseBody
    public ResponseEntity<StreamingResponseBody> getResource(HttpServletRequest request, @PathVariable String id, @RequestParam(value = "system", required = false) String system) throws FileNotFoundException, IOException {

        final Instant start = Instant.now();

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

        final String queryParameter = request.getQueryString();
        final String itemUrl = baseUrl + request.getRequestURI() + ((queryParameter == null || queryParameter.isBlank()) ? "" : "?" + queryParameter);

        final StreamingResponseBody stream = outputStream -> {
            try {
                LOG.info("{}: Start transformation...", id);
                final Response response = httpClient.newCall(getRequest).execute();
                if (response.isSuccessful()) {

                    final XdmNode doc = db.build(new StreamSource(response.body().source().inputStream()));

                    final StringWriter stringWriter = new StringWriter();
                    final Serializer ss = processor.newSerializer(stringWriter);
                    ss.setOutputProperty(Serializer.Property.METHOD, "xml");
                    ss.setOutputProperty(Serializer.Property.INDENT, "yes");

                    // 3. Schreiben
                    ss.serializeNode(doc);

                    final XPathSelector typeSelector = checkExpr.load();
                    typeSelector.setContextItem(doc);

                    final XdmItem result = typeSelector.evaluateSingle();
                    final String typeValue = result != null ? result.getStringValue() : "";

                    if ("http://www.loc.gov/METS/".equalsIgnoreCase(typeValue)) {

                        LOG.info("{}: Using METS/MODS metadata...", id);

                        // METS/MODS     
                        final XPathSelector metsModsSelector = recordExpr.load();
                        metsModsSelector.setContextItem(doc);

                        final XdmItem recordItem = metsModsSelector.evaluateSingle();
                        final String metModsXml = recordItem.getStringValue().trim();

                        final XdmNode metModsDoc = db.build(new StreamSource(new StringReader(metModsXml)));

                        // Provider
                        final XPathSelector providerSelector = providerInfoExpr.load();
                        providerSelector.setContextItem(doc);
                        final XdmItem providerItem = providerSelector.evaluateSingle();

                        final XsltTransformer transformer01 = templatesMetsmodsToIiif.load();
                        transformer01.setParameter(new QName("itemId"), new XdmAtomicValue(id));
                        transformer01.setParameter(new QName("itemUrl"), new XdmAtomicValue(itemUrl));
                        transformer01.setParameter(new QName("providerInfo"), providerItem);

                        final Serializer serializer = processor.newSerializer(outputStream);
                        serializer.setOutputProperty(Serializer.Property.METHOD, "json");
                        serializer.setOutputProperty(Serializer.Property.INDENT, "yes");

                        transformer01.setInitialContextNode(maybeReplaceWithMetadata(metModsDoc));
                        transformer01.setDestination(serializer);
                        transformer01.transform();

                    } else {

                        LOG.info("{}: Using Cortex metadata...", id);

                        final XdmDestination intermediateResult = new XdmDestination();

                        // 1. Cortex zu IIIF-XML
                        final XsltTransformer transformer01 = templatesCortexToIiif.load();
                        transformer01.setURIResolver(new CustomResolver());
                        transformer01.setParameter(new QName("uri"), new XdmAtomicValue(itemUrl));
                        transformer01.setInitialContextNode(doc);
                        transformer01.setDestination(intermediateResult);
                        transformer01.transform();

                        // 2. IIIF-XML → IIIF-JSON
                        final Serializer serializer = processor.newSerializer(outputStream);
                        serializer.setOutputProperty(Serializer.Property.METHOD, "text");
                        serializer.setOutputProperty(Serializer.Property.INDENT, "no");

                        final XsltTransformer transformer02 = templatesXmlToJson.load();
                        transformer02.setInitialContextNode(intermediateResult.getXdmNode());
                        transformer02.setDestination(serializer);
                        transformer02.transform();
                    }
                }
            } catch (Exception e) {
                LOG.error("{}: {}", id, e.getMessage(), e);
                outputStream.write(("{\"error\": \"" + StringEscapeUtils.escapeJson(e.getMessage()) + "\"}").getBytes(StandardCharsets.UTF_8));
            }

            final Instant end = Instant.now();
            final Duration duration = Duration.between(start, end);

            LOG.info("{}: Transformation finshed in {} Sek. ", id, df.format(duration.toMillis() / 1000.0));
        };

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_JSON)
                .body(stream);
    }
}
