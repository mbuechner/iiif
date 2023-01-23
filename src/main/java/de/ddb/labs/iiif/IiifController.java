/*
 * Copyright 2023 Michael Büchner, Deutsche Digitale Bibliothek
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
import java.io.InputStream;
import java.io.StringWriter;
import java.net.URISyntaxException;
import java.util.concurrent.TimeUnit;
import javax.xml.transform.Templates;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import lombok.extern.slf4j.Slf4j;
import okhttp3.Dispatcher;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
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
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*", maxAge = 3600)
@Slf4j
class IiifController {

    private final static String DDB_API = "https://api.deutsche-digitale-bibliothek.de/items/";
    private final static String API_KEY = "?oauth_consumer_key=";
    private final OkHttpClient httpClient;
    private final TransformerFactory factory;

    @Value("${iiif.baseurl}")
    private String baseUrl;

    @Value("${iiif.ddb_api_key}")
    private String ddbApiKey;

    @Value("classpath:transform-to-xml.xsl")
    private Resource transformToXml;
    private Templates templates01;

    @Value("classpath:transform-to-json.xsl")
    private Resource transformatToJson;
    private Templates templates02;

    public IiifController() throws URISyntaxException, IOException {
        final Dispatcher dispatcher = new Dispatcher();
        dispatcher.setMaxRequests(64);
        dispatcher.setMaxRequestsPerHost(8);
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(5, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .dispatcher(dispatcher)
                .build();

        factory = new net.sf.saxon.TransformerFactoryImpl();
    }

    @EventListener(ApplicationReadyEvent.class)
    public void doSomethingAfterStartup() throws TransformerConfigurationException, IOException {

        final StreamSource ss01 = new StreamSource(transformToXml.getInputStream());
        final StreamSource ss02 = new StreamSource(transformatToJson.getInputStream());

        templates01 = factory.newTemplates(ss01);
        templates02 = factory.newTemplates(ss02);
    }

    @RequestMapping(
            method = RequestMethod.GET,
            produces = "application/json",
            value = "/"
    )
    @ResponseBody
    public ResponseEntity<String> getRoot() {
        return ResponseEntity.ok().body("{ \"Message\": \"Hello! :)\" }");
    }

    @RequestMapping(
            method = RequestMethod.GET,
            produces = "application/json",
            value = "/{id}"
    )
    @ResponseBody
    public ResponseEntity<String> getResource(HttpServletRequest request, @PathVariable String id) throws FileNotFoundException, IOException, TransformerConfigurationException, TransformerException {

        final Request getRequest = new Request.Builder()
                .url(DDB_API + id + API_KEY + ddbApiKey)
                .addHeader("Accept", "application/xml")
                .get()
                .build();

        try (final Response response = httpClient.newCall(getRequest).execute()) {
            if (response.isSuccessful()) {

                final InputStream inputXmlString = response.body().byteStream();

                final StringWriter writer = new StringWriter();
                final StreamResult result = new StreamResult(writer);

                final Transformer transformer01 = templates01.newTransformer();
                transformer01.setParameter("uri", baseUrl + request.getRequestURI());

                final TransformerHandler transformer02 = ((SAXTransformerFactory) factory).newTransformerHandler(templates02);
                transformer02.setResult(result);

                transformer01.transform(new StreamSource(inputXmlString), new SAXResult(transformer02));

                return ResponseEntity.ok().body(writer.toString());
            } else {
                return ResponseEntity.status(HttpStatusCode.valueOf(404)).body("{ \"Error\": \"" + id + " is not a valid DDB id\" }");
            }
        }
    }
}
