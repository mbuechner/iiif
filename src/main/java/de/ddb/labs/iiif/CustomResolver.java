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

import net.sf.saxon.lib.StandardURIResolver;
import net.sf.saxon.trans.XPathException;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import java.io.InputStream;
import java.util.Objects;
import java.util.concurrent.TimeUnit;
import okhttp3.Dispatcher;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;

public class CustomResolver extends StandardURIResolver {

    private final OkHttpClient httpClient;

    public CustomResolver() {
        final Dispatcher dispatcher = new Dispatcher();
        dispatcher.setMaxRequests(64);
        dispatcher.setMaxRequestsPerHost(8);
        httpClient = new OkHttpClient.Builder()
                .connectTimeout(5, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .dispatcher(dispatcher)
                .build();
    }

    @Override
    public Source resolve(String href, String base) throws XPathException {
        try {
            final Request request = new Request.Builder()
                    .url(href)
                    .header("Accept", "application/xml")
                    .build();

            final Response response = httpClient.newCall(request).execute();
            if (!response.isSuccessful()) {
                throw new XPathException("HTTP-Fehler: " + response.code() + " - " + response.message());
            }

            final ResponseBody body = Objects.requireNonNull(response.body());
            final InputStream inputStream = body.byteStream();

            return new StreamSource(inputStream, href);
        } catch (Exception e) {
            throw new XPathException("Fehler beim Laden von " + href + ": " + e.getMessage(), e);
        }
    }
}
