<?xml version="1.0" encoding="UTF-8"?>
<!-- 
Copyright 2023 Michael Büchner, Deutsche Digitale Bibliothek

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
<xsl:stylesheet exclude-result-prefixes="cortex ns3 ns4" version="3.0" xmlns="http://www.w3.org/2005/xpath-functions" xmlns:cortex="http://www.deutsche-digitale-bibliothek.de/cortex" xmlns:ns3="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:ns4="http://www.deutsche-digitale-bibliothek.de/item" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="UTF-8" method="xml" />
    <!-- uri of this record -->
    <xsl:param name="uri">https://labs.deutsche-digitale-bibliothek.de/iiif/presentation/3/ABCDEFGHIJKLMNOPQRSTUVWXYZ012345</xsl:param>
    <!-- root template -->
    <xsl:template match="/">
        <!-- variables -->
        <!-- id of this record -->
        <xsl:variable name="id">
            <xsl:value-of select="/cortex:cortex/cortex:properties/cortex:item-id" />
        </xsl:variable>
        <!-- id of the provider of this record -->
        <xsl:variable name="providerId">
            <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-ddb-id" />
        </xsl:variable>
        <!-- url to provider record -->
        <!-- TODO: change the following url, when DDB api doesn't require a key anymore -->
        <xsl:variable name="providerUrl">
            <xsl:text>https://www.deutsche-digitale-bibliothek.de/item/xml/</xsl:text>
            <xsl:value-of select="$providerId" />
        </xsl:variable>
        <!-- logo uuid of provider -->
        <xsl:variable name="providerLogo">
            <xsl:value-of select="document($providerUrl)/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true']/@ref" />
        </xsl:variable>
        <!-- start of record -->
        <map>
            <string key="@context">http://iiif.io/api/presentation/3/context.json</string>
            <string key="id">
                <xsl:value-of select="$uri" />
            </string>
            <string key="type">Manifest</string>
            <map key="label">
                <array key="de">
                    <string>
                        <xsl:value-of select="/cortex:cortex/cortex:view/ns4:item/ns4:title" />
                    </string>
                </array>
            </map>
            <!-- metadata block -->
            <array key="metadata">
                <xsl:for-each select="/cortex:cortex/cortex:view/ns4:item/ns4:fields[@usage = 'display']/ns4:field">
                    <map>
                        <map key="label">
                            <array key="de">
                                <string>
                                    <xsl:value-of select="ns4:name" />
                                </string>
                            </array>
                        </map>
                        <map key="value">
                            <array key="none">
                                <xsl:for-each select="ns4:value">
                                    <string>
                                        <xsl:choose>
                                            <xsl:when test="@ns3:resource">
                                                <xsl:text>&lt;a href="</xsl:text>
                                                <xsl:value-of select="@ns3:resource" />
                                                <xsl:text>" target="_blank"&gt;</xsl:text>
                                                <xsl:value-of select="." />
                                                <xsl:text>&lt;/a&gt;</xsl:text>
                                            </xsl:when>
                                            <xsl:when test="starts-with(., 'http://') or starts-with(., 'https://')">
                                                <xsl:text>&lt;a href="</xsl:text>
                                                <xsl:value-of select="." />
                                                <xsl:text>" target="_blank"&gt;</xsl:text>
                                                <xsl:value-of select="." />
                                                <xsl:text>&lt;/a&gt;</xsl:text>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="." />
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </string>
                                </xsl:for-each>
                            </array>
                        </map>
                    </map>
                </xsl:for-each>
            </array>
            <!-- summary block -->
            <xsl:if test="/cortex:cortex/cortex:view/ns4:item/ns4:fields[@usage = 'display']/ns4:field[@id = 'flex_mus_neu_050' or @id = 'flex_film_007']">
                <map key="summary">
                    <array key="de">
                        <xsl:for-each select="/cortex:cortex/cortex:view/ns4:item/ns4:fields[@usage = 'display']/ns4:field[@id = 'flex_mus_neu_050' or @id = 'flex_film_007']/ns4:value">
                            <string>
                                <xsl:value-of select="." />
                            </string>
                        </xsl:for-each>
                    </array>
                </map>
            </xsl:if>
            <!-- thumbnail block -->
            <xsl:if test="/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true']">
                <xsl:variable name="thumbId">
                    <xsl:value-of select="/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true'][1]/@ref" />
                </xsl:variable>
                <array key="thumbnail">
                    <map>
                        <string key="id">
                            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                            <xsl:value-of select="$thumbId" />
                            <xsl:text>/full/200,/0/default.jpg</xsl:text>
                        </string>
                        <string key="type">Image</string>
                        <string key="format">image/jpeg</string>
                        <array key="service">
                            <map>
                                <string key="id">
                                    <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                    <xsl:value-of select="$thumbId" />
                                </string>
                                <string key="type">ImageService2</string>
                                <string key="profile">level2</string>
                            </map>
                        </array>
                    </map>
                </array>
            </xsl:if>
            <!-- viewingDirection (hard coded) -->
            <string key="viewingDirection">left-to-right</string>
            <!-- behavior (hard coded) -->
            <array key="behavior">
                <string>individuals</string>
            </array>
            <!-- rights of metadata -->
            <string key="rights">
                <xsl:value-of select="/cortex:cortex/cortex:view/ns4:item/ns4:license/@ns3:resource" />
            </string>
            <!-- requiredStatement -->
            <map key="requiredStatement">
                <map key="label">
                    <array key="en">
                        <string>Attribution</string>
                    </array>
                    <array key="de">
                        <string>Zuschreibung</string>
                    </array>
                </map>
                <map key="value">
                    <array key="none">
                        <string>
                            <xsl:choose>
                                <xsl:when test="cortex:cortex/cortex:view/ns4:item/ns4:origin and string-length(cortex:cortex/cortex:view/ns4:item/ns4:origin) > 0">
                                    <xsl:text>&lt;a href="</xsl:text>
                                    <xsl:value-of select="cortex:cortex/cortex:view/ns4:item/ns4:origin" />
                                    <xsl:text>" target="_blank"&gt;</xsl:text>
                                    <xsl:value-of select="/cortex:cortex/cortex:view/ns4:item/ns4:institution/ns4:name" />
                                    <xsl:text>&lt;/a&gt;</xsl:text>
                                </xsl:when>
                                <xsl:when test="/cortex:cortex/cortex:provider-info/cortex:provider-uri and string-length(/cortex:cortex/cortex:provider-info/cortex:provider-uri) > 0">
                                    <xsl:text>&lt;a href="</xsl:text>
                                    <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-uri" />
                                    <xsl:text>" target="_blank"&gt;</xsl:text>
                                    <xsl:value-of select="/cortex:cortex/cortex:view/ns4:item/ns4:institution/ns4:name" />
                                    <xsl:text>&lt;/a&gt;</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="/cortex:cortex/cortex:view/ns4:item/ns4:institution/ns4:name" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </string>
                    </array>
                </map>
            </map>
            <!-- provider -->
            <array key="provider">
                <map>
                    <string key="id">
                        <xsl:text>https://www.deutsche-digitale-bibliothek.de/organization/</xsl:text>
                        <xsl:value-of select="$providerId" />
                    </string>
                    <string key="type">Agent</string>
                    <map key="label">
                        <array key="none">
                            <string>
                                <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-name" />
                            </string>
                        </array>
                    </map>
                    <array key="seeAlso">
                        <map>
                            <string key="id">
                                <xsl:text>https://www.deutsche-digitale-bibliothek.de/organization/</xsl:text>
                                <xsl:value-of select="$providerId" />
                            </string>
                            <string key="type">Text</string>
                            <map key="label">
                                <array key="de">
                                    <string>
                                        <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-name" />
                                        <xsl:text> bei der Deutschen Digitalen Bibliothek</xsl:text>
                                    </string>
                                </array>
                            </map>
                            <string key="format">text/html</string>
                        </map>
                    </array>
                    <xsl:if test="$providerLogo != ''">
                        <array key="logo">
                            <map>
                                <string key="id">
                                    <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                    <xsl:value-of select="$providerLogo" />
                                    <xsl:text>/full/full/0/default.jpg</xsl:text>
                                </string>
                                <string key="type">Image</string>
                                <string key="format">image/jpg</string>
                                <array key="service">
                                    <map>
                                        <string key="id">
                                            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                            <xsl:value-of select="$providerLogo" />
                                        </string>
                                        <string key="type">ImageService2</string>
                                        <string key="profile">level2</string>
                                    </map>
                                </array>
                            </map>
                        </array>
                    </xsl:if>
                    <xsl:if test="/cortex:cortex/cortex:provider-info/cortex:provider-uri">
                        <array key="homepage">
                            <map>
                                <string key="id">
                                    <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-uri" />
                                </string>
                                <string key="type">Text</string>
                                <map key="label">
                                    <array key="none">
                                        <string>
                                            <xsl:value-of select="/cortex:cortex/cortex:provider-info/cortex:provider-name" />
                                        </string>
                                    </array>
                                </map>
                                <string key="format">text/html</string>
                            </map>
                        </array>
                    </xsl:if>
                </map>
            </array>
            <!-- homepage -->
            <array key="homepage">
                <map>
                    <string key="id">
                        <xsl:text>https://www.deutsche-digitale-bibliothek.de/item/</xsl:text>
                        <xsl:value-of select="$id" />
                    </string>
                    <string key="type">Text</string>
                    <map key="label">
                        <array key="none">
                            <string>Deutsche Digitale Bibliothek</string>
                        </array>
                    </map>
                    <string key="format">text/html</string>
                </map>
            </array>
            <!-- logo -->
            <!-- TODO: logo at this position is not IIIF Presentation v3 valid, but Mirador 3 will display a logo (which is nice) -->
            <xsl:if test="$providerLogo">
                <array key="logo">
                    <map>
                        <string key="id">
                            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                            <xsl:value-of select="$providerLogo" />
                            <xsl:text>/full/full/0/default.jpg</xsl:text>
                        </string>
                        <string key="type">Image</string>
                        <string key="format">image/jpg</string>
                        <array key="service">
                            <map>
                                <string key="id">
                                    <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                    <xsl:value-of select="$providerLogo" />
                                </string>
                                <string key="type">ImageService2</string>
                                <string key="profile">level2</string>
                            </map>
                        </array>
                    </map>
                </array>
            </xsl:if>
            <!-- seeAlso -->
            <array key="seeAlso">
                <map>
                    <string key="id">
                        <xsl:text>https://api.deutsche-digitale-bibliothek.de/items/</xsl:text>
                        <xsl:value-of select="$id" />
                    </string>
                    <string key="type">Dataset</string>
                    <string key="format">application/xml</string>
                    <string key="profile">https://www.deutsche-digitale-bibliothek.de/ns/cortex</string>
                </map>
            </array>
            <!-- rendering -->
            <!-- 
            "rendering": [
                {
                    "id": "https://api.deutsche-digitale-bibliothek.de/binary/8fac26ef-8b2d-47ef-94c3-259326c82ac4.pdf",
                    "type": "Text",
                    "label":
                    {
                        "de": ["PDF-Ansicht"]
                    },
                    "format": "application/pdf"
                }
            ],
            -->
            <xsl:if test="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'application/pdf']">
                <array key="rendering">
                    <xsl:for-each select="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'application/pdf']">
                        <map>
                            <string key="id">
                                <xsl:text>https://api.deutsche-digitale-bibliothek.de/binary/</xsl:text>
                                <xsl:value-of select="@ref" />
                                <xsl:text>.pdf</xsl:text>
                            </string>
                            <string key="type">Text</string>
                            <map key="label">
                                <array key="de">
                                    <string>PDF-Ansicht</string>
                                </array>
                            </map>
                            <string key="format">application/pdf</string>
                        </map>
                    </xsl:for-each>
                </array>
            </xsl:if>
            <!-- start (canvas) -->
            <map key="start">
                <string key="id">
                    <xsl:value-of select="$uri" />
                    <xsl:text>/canvas/p</xsl:text>
                    <xsl:value-of select="head(index-of(/cortex:cortex/cortex:binaries/cortex:binary/@primary, 'true'))" />
                </string>
                <string key="type">Canvas</string>
            </map>
            <!-- items -->
            <array key="items">
                <xsl:apply-templates />
            </array>
            <!-- structures -->
            <array key="structures">
                <map>
                    <string key="id">
                        <xsl:value-of select="$uri" />
                        <xsl:text>/range/r0</xsl:text>
                    </string>
                    <string key="type">Range</string>
                    <map key="label">
                        <array key="de">
                            <string>Übersicht</string>
                        </array>
                        <array key="en">
                            <string>Content</string>
                        </array>
                    </map>
                    <array key="items">
                        <xsl:for-each select="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'image/jpeg' or @mimetype = 'application/pdf' or @mimetype = 'video/mp4' or @mimetype = 'audio/mpeg']">
                            <map>
                                <string key="id">
                                    <xsl:value-of select="$uri" />
                                    <xsl:text>/range/r</xsl:text>
                                    <xsl:value-of select="position()" />
                                </string>
                                <string key="type">Range</string>
                                <map key="label">
                                    <array key="de">
                                        <string>
                                            <xsl:choose>
                                                <xsl:when test="@name3 and string-length(@name3) > 0">
                                                    <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                                                </xsl:when>
                                                <xsl:when test="@name2 and string-length(@name2) > 0">
                                                    <xsl:value-of select="concat(@name, ' | ', @name2)" />
                                                </xsl:when>
                                                <xsl:when test="@name and string-length(@name) > 0">
                                                    <xsl:value-of select="@name" />
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:text>Digitalisat </xsl:text>
                                                    <xsl:value-of select="position()" />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </string>
                                    </array>
                                </map>
                                <array key="items">
                                    <map>
                                        <string key="id">
                                            <xsl:value-of select="$uri" />
                                            <xsl:text>/canvas/p</xsl:text>
                                            <xsl:value-of select="position()" />
                                        </string>
                                        <string key="type">Canvas</string>
                                    </map>
                                </array>
                            </map>
                        </xsl:for-each>
                    </array>
                </map>
            </array>
            <!--  -->
        </map>
    </xsl:template>
    <!-- template for images -->
    <xsl:template match="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'image/jpeg']">
        <xsl:variable name="infoJsonUrl">
            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
            <xsl:value-of select="@ref" />
            <xsl:text>/info.json</xsl:text>
        </xsl:variable>
        <xsl:variable as="map(*)" name="infoJson" select="json-doc($infoJsonUrl)" />
        <xsl:variable name="imageWidth" select="$infoJson?width" />
        <xsl:variable name="imageHeight" select="$infoJson?height" />
        <map>
            <string key="id">
                <xsl:value-of select="$uri" />
                <xsl:text>/canvas/p</xsl:text>
                <xsl:value-of select="position()" />
            </string>
            <string key="type">Canvas</string>
            <map key="label">
                <array key="de">
                    <string>
                        <xsl:choose>
                            <xsl:when test="@name3 and string-length(@name3) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                            </xsl:when>
                            <xsl:when test="@name2 and string-length(@name2) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2)" />
                            </xsl:when>
                            <xsl:when test="@name and string-length(@name) > 0">
                                <xsl:value-of select="@name" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Digitalisat </xsl:text>
                                <xsl:value-of select="position()" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </string>
                </array>
            </map>
            <number key="height">
                <xsl:value-of select="$imageHeight" />
            </number>
            <number key="width">
                <xsl:value-of select="$imageWidth" />
            </number>
            <array key="items">
                <map>
                    <string key="id">
                        <xsl:value-of select="$uri" />
                        <xsl:text>/canvas/p</xsl:text>
                        <xsl:value-of select="position()" />
                        <xsl:text>/1</xsl:text>
                    </string>
                    <string key="type">AnnotationPage</string>
                    <array key="items">
                        <!-- images and pdf (pdf always have a preview image) -->
                        <map>
                            <string key="id">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/annotation/p0001-image</xsl:text>
                            </string>
                            <string key="type">Annotation</string>
                            <string key="motivation">painting</string>
                            <map key="body">
                                <string key="id">
                                    <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                    <xsl:value-of select="@ref" />
                                    <xsl:text>/full/full/0/default.jpg</xsl:text>
                                </string>
                                <string key="type">Image</string>
                                <string key="format">image/jpeg</string>
                                <array key="service">
                                    <map>
                                        <string key="id">
                                            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                            <xsl:value-of select="@ref" />
                                        </string>
                                        <string key="type">ImageService2</string>
                                        <string key="profile">level2</string>
                                    </map>
                                </array>
                                <number key="height">
                                    <xsl:value-of select="$imageHeight" />
                                </number>
                                <number key="width">
                                    <xsl:value-of select="$imageWidth" />
                                </number>
                                <array key="metadata">
                                    <map>
                                        <map key="label">
                                            <array key="de">
                                                <string>Beschreibung</string>
                                            </array>
                                        </map>
                                        <map key="value">
                                            <array key="de">
                                                <string>
                                                    <xsl:choose>
                                                        <xsl:when test="@name3 and string-length(@name3) > 0">
                                                            <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                                                        </xsl:when>
                                                        <xsl:when test="@name2 and string-length(@name2) > 0">
                                                            <xsl:value-of select="concat(@name, ' | ', @name2)" />
                                                        </xsl:when>
                                                        <xsl:when test="@name and string-length(@name) > 0">
                                                            <xsl:value-of select="@name" />
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:text>Digitalisat </xsl:text>
                                                            <xsl:value-of select="position()" />
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </string>
                                            </array>
                                        </map>
                                    </map>
                                </array>
                            </map>
                            <string key="target">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/canvas/p</xsl:text>
                                <xsl:value-of select="position()" />
                                <xsl:text>/1</xsl:text>
                            </string>
                        </map>
                    </array>
                </map>
            </array>
            <!-- thumbnail -->
            <array key="thumbnail">
                <map>
                    <string key="id">
                        <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                        <xsl:value-of select="@ref" />
                        <xsl:text>/full/full/0/default.jpg</xsl:text>
                    </string>
                    <string key="type">Image</string>
                    <string key="format">image/jpeg</string>
                    <array key="service">
                        <map>
                            <string key="id">
                                <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                <xsl:value-of select="@ref" />
                            </string>
                            <string key="type">ImageService2</string>
                            <string key="profile">level2</string>
                        </map>
                    </array>
                </map>
            </array>
        </map>
    </xsl:template>
    <!-- template for pdf -->
    <xsl:template match="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'application/pdf']">
        <map>
            <string key="id">
                <xsl:value-of select="$uri" />
                <xsl:text>/canvas/p</xsl:text>
                <xsl:value-of select="position()" />
            </string>
            <string key="type">Canvas</string>
            <map key="label">
                <array key="de">
                    <string>
                        <xsl:choose>
                            <xsl:when test="@name3 and string-length(@name3) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                            </xsl:when>
                            <xsl:when test="@name2 and string-length(@name2) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2)" />
                            </xsl:when>
                            <xsl:when test="@name and string-length(@name) > 0">
                                <xsl:value-of select="@name" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Digitalisat </xsl:text>
                                <xsl:value-of select="position()" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </string>
                </array>
            </map>
            <array key="items">
                <map>
                    <string key="id">
                        <xsl:value-of select="$uri" />
                        <xsl:text>/canvas/p</xsl:text>
                        <xsl:value-of select="position()" />
                        <xsl:text>/1</xsl:text>
                    </string>
                    <string key="type">AnnotationPage</string>
                    <array key="items">
                        <map>
                            <string key="id">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/annotation/p0001-document</xsl:text>
                            </string>
                            <string key="type">Annotation</string>
                            <string key="motivation">painting</string>
                            <map key="body">
                                <string key="id">
                                    <xsl:text>https://api.deutsche-digitale-bibliothek.de/binary/</xsl:text>
                                    <xsl:value-of select="@ref" />
                                    <xsl:text>.pdf</xsl:text>
                                </string>
                                <string key="type">Document</string>
                                <string key="format">application/pdf</string>
                                <array key="metadata">
                                    <map>
                                        <map key="label">
                                            <array key="de">
                                                <string>Beschreibung</string>
                                            </array>
                                        </map>
                                        <map key="value">
                                            <array key="de">
                                                <string>
                                                    <xsl:choose>
                                                        <xsl:when test="@name3 and string-length(@name3) > 0">
                                                            <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                                                        </xsl:when>
                                                        <xsl:when test="@name2 and string-length(@name2) > 0">
                                                            <xsl:value-of select="concat(@name, ' | ', @name2)" />
                                                        </xsl:when>
                                                        <xsl:when test="@name and string-length(@name) > 0">
                                                            <xsl:value-of select="@name" />
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:text>Digitalisat </xsl:text>
                                                            <xsl:value-of select="position()" />
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </string>
                                            </array>
                                        </map>
                                    </map>
                                </array>
                            </map>
                            <string key="target">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/canvas/p</xsl:text>
                                <xsl:value-of select="position()" />
                                <xsl:text>/1</xsl:text>
                            </string>
                        </map>
                    </array>
                </map>
            </array>
            <!-- thumbnail, because every PDF does have an thumbnail -->
            <array key="thumbnail">
                <map>
                    <string key="id">
                        <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                        <xsl:value-of select="@ref" />
                        <xsl:text>/full/full/0/default.jpg</xsl:text>
                    </string>
                    <string key="type">Image</string>
                    <string key="format">image/jpeg</string>
                    <array key="service">
                        <map>
                            <string key="id">
                                <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                <xsl:value-of select="@ref" />
                            </string>
                            <string key="type">ImageService2</string>
                            <string key="profile">level2</string>
                        </map>
                    </array>
                </map>
            </array>
        </map>
    </xsl:template>
    <!-- template for video -->
    <xsl:template match="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'video/mp4']">
        <map>
            <string key="id">
                <xsl:value-of select="$uri" />
                <xsl:text>/canvas/p</xsl:text>
                <xsl:value-of select="position()" />
            </string>
            <string key="type">Canvas</string>
            <map key="label">
                <array key="de">
                    <string>
                        <xsl:choose>
                            <xsl:when test="@name3 and string-length(@name3) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                            </xsl:when>
                            <xsl:when test="@name2 and string-length(@name2) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2)" />
                            </xsl:when>
                            <xsl:when test="@name and string-length(@name) > 0">
                                <xsl:value-of select="@name" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Digitalisat </xsl:text>
                                <xsl:value-of select="position()" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </string>
                </array>
            </map>
            <number key="height">360</number>
            <number key="width">480</number>
            <number key="duration">321.0</number>
            <array key="items">
                <map>
                    <string key="id">
                        <xsl:value-of select="$uri" />
                        <xsl:text>/canvas/p</xsl:text>
                        <xsl:value-of select="position()" />
                        <xsl:text>/1</xsl:text>
                    </string>
                    <string key="type">AnnotationPage</string>
                    <array key="items">
                        <!-- videos -->
                        <map>
                            <string key="id">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/annotation/p0001-image</xsl:text>
                            </string>
                            <string key="type">Annotation</string>
                            <string key="motivation">painting</string>
                            <map key="body">
                                <string key="id">
                                    <xsl:text>https://api.deutsche-digitale-bibliothek.de/binary/</xsl:text>
                                    <xsl:value-of select="@ref" />
                                    <xsl:text>.mp4</xsl:text>
                                </string>
                                <string key="type">Video</string>
                                <number key="height">360</number>
                                <number key="width">480</number>
                                <!-- we don't know the duration and we'll never know -->
                                <number key="duration">321.0</number>
                                <string key="format">video/mp4</string>
                            </map>
                            <string key="target">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/canvas/p</xsl:text>
                                <xsl:value-of select="position()" />
                                <xsl:text>/1</xsl:text>
                            </string>
                        </map>
                    </array>
                </map>
            </array>
            <!-- thumbnail, because every video does have an thumbnail -->
            <xsl:if test="/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true' and @mimetype = 'image/jpeg']/@ref">
                <array key="thumbnail">
                    <map>
                        <string key="id">
                            <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                            <xsl:value-of select="/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true' and @mimetype = 'image/jpeg']/@ref" />
                            <xsl:text>/full/full/0/default.jpg</xsl:text>
                        </string>
                        <string key="type">Image</string>
                        <string key="format">image/jpeg</string>
                        <array key="service">
                            <map>
                                <string key="id">
                                    <xsl:text>https://iiif.deutsche-digitale-bibliothek.de/image/2/</xsl:text>
                                    <xsl:value-of select="/cortex:cortex/cortex:binaries/cortex:binary[@primary = 'true' and @mimetype = 'image/jpeg']/@ref" />
                                </string>
                                <string key="type">ImageService2</string>
                                <string key="profile">level2</string>
                            </map>
                        </array>
                    </map>
                </array>
            </xsl:if>
        </map>
    </xsl:template>
    <!-- template for audio -->
    <xsl:template match="/cortex:cortex/cortex:binaries/cortex:binary[@mimetype = 'audio/mpeg']">
        <map>
            <string key="id">
                <xsl:value-of select="$uri" />
                <xsl:text>/canvas/p</xsl:text>
                <xsl:value-of select="position()" />
            </string>
            <string key="type">Canvas</string>
            <map key="label">
                <array key="de">
                    <string>
                        <xsl:choose>
                            <xsl:when test="@name3 and string-length(@name3) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2, ' | ', @name3)" />
                            </xsl:when>
                            <xsl:when test="@name2 and string-length(@name2) > 0">
                                <xsl:value-of select="concat(@name, ' | ', @name2)" />
                            </xsl:when>
                            <xsl:when test="@name and string-length(@name) > 0">
                                <xsl:value-of select="@name" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:text>Digitalisat </xsl:text>
                                <xsl:value-of select="position()" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </string>
                </array>
            </map>
            <array key="items">
                <map>
                    <string key="id">
                        <xsl:value-of select="$uri" />
                        <xsl:text>/canvas/p</xsl:text>
                        <xsl:value-of select="position()" />
                        <xsl:text>/1</xsl:text>
                    </string>
                    <string key="type">AnnotationPage</string>
                    <array key="items">
                        <!-- audio -->
                        <map>
                            <string key="id">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/annotation/p0001-image</xsl:text>
                            </string>
                            <string key="type">Annotation</string>
                            <string key="motivation">painting</string>
                            <map key="body">
                                <string key="id">
                                    <xsl:text>https://api.deutsche-digitale-bibliothek.de/binary/</xsl:text>
                                    <xsl:value-of select="@ref" />
                                    <xsl:text>.mp4</xsl:text>
                                </string>
                                <string key="type">Sound</string>
                                <!-- <number key="duration">96.0</number> -->
                                <string key="format">audio/mp4</string>
                            </map>
                            <string key="target">
                                <xsl:value-of select="$uri" />
                                <xsl:text>/canvas/p</xsl:text>
                                <xsl:value-of select="position()" />
                                <xsl:text>/1</xsl:text>
                            </string>
                        </map>
                    </array>
                </map>
            </array>
        </map>
    </xsl:template>
    <!-- default template -->
    <xsl:template match="text() | @*" />
</xsl:stylesheet>
