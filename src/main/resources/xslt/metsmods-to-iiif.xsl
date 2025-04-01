<?xml version="1.0" encoding="UTF-8"?>
<!-- 
Copyright 2025 Michael Büchner, Deutsche Digitale Bibliothek

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
<xsl:stylesheet version="3.0" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:ddblabs="https://labs.deutsche-digitale-bibliothek.de" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:mets="http://www.loc.gov/METS/" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:saxon="http://saxon.sf.net/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- <xsl:output encoding="UTF-8" indent="yes" method="json" saxon:property-order="id @context type @ a b c d e f g h i j k l m n o p q r s t u v w x y z * $" use-character-maps="no-escape-slash" /> -->
    <xsl:output encoding="UTF-8" indent="yes" method="json" use-character-maps="no-escape-slash" />
    <xsl:strip-space elements="*" />
    <xsl:character-map name="no-escape-slash">
        <xsl:output-character character="/" string="/" />
    </xsl:character-map>
    <!-- Global variables (these should be set from outside) -->
    <xsl:variable name="ddbId" select="'TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO'" />
    <xsl:variable name="providerId" select="'EGCA66RQCQZMVMLIFI74MXN4PU2Q6AF3'" />
    <xsl:variable name="selfUrl" select="'https://iiif.deutsche-digitale-bibliothek.de/presentation/3/' || $ddbId" />
    <xsl:function as="xs:string" name="ddblabs:normalizeUrl">
        <!--
        Funktion: ddblabs:normalizeUrl
        Beschreibung: Entfernt den abschließenden Schrägstrich von einer URL, falls vorhanden.
        Parameter:
            $url (xs:string) - Die URL, die normiert werden soll.
        Rückgabewert: xs:string - Die normierte URL ohne abschließenden Schrägstrich.
        Beispiel:
            ddblabs:normalizeUrl('http://example.com/') gibt 'http://example.com' zurück.
        -->
        <xsl:param as="xs:string" name="url" />
        <xsl:sequence select="replace($url, '/$', '')" />
    </xsl:function>
    <xsl:function as="xs:string" name="ddblabs:generateLink">
        <!--
        Funktion: ddblabs:generateLink
        Beschreibung: Erstellt einen HTML-Link (<a>-Tag) aus einem angegebenen Text und einer URL.
                      Optional kann der Link so eingestellt werden, dass er in einem neuen Tab/Fenster geöffnet wird.
        Parameter:
            - text (xs:string): Der Text, der als Link angezeigt werden soll.
            - url (xs:string): Die URL, auf die der Link verweisen soll.
            - blank (xs:boolean): Optional. Wenn true, wird dem Link das Attribut target="_blank" hinzugefügt,
                                   um ihn in einem neuen Tab/Fenster zu öffnen. Default ist false.
        Rückgabewert: Ein String, der einen HTML-Link (<a>-Tag) darstellt.
        Beispiel: ddblabs:generateLink('DDB', 'https://www.ddb.de', true()) erzeugt den String
                  '<a href="https://www.ddb.com" target="_blank">DDB</a>'.
        -->
        <xsl:param as="xs:string" name="text" />
        <xsl:param as="xs:string" name="url" />
        <xsl:param as="xs:boolean" name="blank" />
        <xsl:variable name="targetAttr" select="
                if ($blank) then
                    ' target=&quot;_blank&quot;'
                else
                    ''" />
        <xsl:sequence select="concat('&lt;a href=&quot;', $url, '&quot;', $targetAttr, '&gt;', $text, '&lt;/a&gt;')" />
    </xsl:function>
    <xsl:function name="ddblabs:generateProvider">
        <xsl:param as="xs:string" name="providerId" />
        <xsl:variable name="providerUrl" select="'https://api.deutsche-digitale-bibliothek.de/2/items/' || $providerId" />
        <xsl:variable name="orgXml" select="doc($providerUrl)" />
        <!--
          "provider": [
            {
            ...
            }
          ],    
        -->
        <xsl:sequence>
            <xsl:map>
                <!-- "id": "https://www.deutsche-digitale-bibliothek.de/organization/EGCA66RQCQZMVMLIFI74MXN4PU2Q6AF3", -->
                <xsl:map-entry key="'id'" select="$providerUrl" />
                <!-- "type": "Agent", -->
                <xsl:map-entry key="'type'" select="'Agent'" />
                <!-- 
                "label": {
                    "none": [
                        "Peter Tamm Sen. Stiftung"
                    ]
                },
                -->
                <xsl:map-entry key="'label'" select="
                        map {
                            'none': array {$orgXml/cortex/view/cortex-institution/name/text()}
                        }" />
                <!-- 
                  "seeAlso": [
                    {
                      "id": "https://www.deutsche-digitale-bibliothek.de/organization/EGCA66RQCQZMVMLIFI74MXN4PU2Q6AF3",
                      "type": "Text",
                      "label": {
                        "de": [
                          "Peter Tamm Sen. Stiftung bei der Deutschen Digitalen Bibliothek"
                        ]
                      },
                      "format": "text/html"
                    }
                  ],
                -->
                <xsl:map-entry key="'seeAlso'" select="
                        array {
                            map {
                                'id': $providerUrl,
                                'type': 'Text',
                                'label': map {
                                    'none': array {$orgXml/cortex/view/cortex-institution/name/text() || ' bei der DeutschenDigitalen Bibliothek'}
                                }
                            }
                        }" />
                <!-- 
                  "logo": [
                     {
                       "id": "https://iiif.deutsche-digitale-bibliothek.de/image/2/8d4a9cf5-7309-47c9-a8e9-d2f6958add47/full/full/0/default.jpg",
                       "type": "Image",
                       "format": "image/jpg",
                       "service": [
                         {
                           "id": "https://iiif.deutsche-digitale-bibliothek.de/image/2/8d4a9cf5-7309-47c9-a8e9-d2f6958add47",
                           "type": "ImageService2",
                           "profile": "level2"
                         }
                       ]
                     }
                   ],                
                -->
                <xsl:map-entry key="'logo'" select="
                        array {
                            map {
                                'id': 'https://iiif.deutsche-digitale-bibliothek.de/image/2/' || $orgXml/cortex/binaries/binary[1]/@ref || '/full/full/0/default.jpg',
                                'type': 'Image',
                                'format': 'image/jpg',
                                'service': array {
                                    map {
                                        'id': 'https://iiif.deutsche-digitale-bibliothek.de/image/2/' || $orgXml/cortex/binaries/binary[1]/@ref,
                                        'type': 'ImageService2',
                                        'profile': 'level2'
                                    }
                                }
                            }
                        }" />
                <!-- 
                  "homepage": [
                    {
                      "id": "https://www.imm-hamburg.de/",
                      "type": "Text",
                      "label": {
                        "none": [
                          "Peter Tamm Sen. Stiftung"
                        ]
                      },
                      "format": "text/html"
                    }
                  ]
                -->
                <xsl:map-entry key="'homepage'" select="
                        array {
                            map {
                                'id': $orgXml/cortex/view/cortex-institution/website[1]/text(),
                                'type': 'Text',
                                'label': map {
                                    'none': array {$orgXml/cortex/view/cortex-institution/name/text()}
                                },
                                'format': 'text/html'
                            }
                        }" />
            </xsl:map>
        </xsl:sequence>
    </xsl:function>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="count(//mets:mets/mets:fileSec/mets:fileGrp/mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']) &gt; 0">
                <xsl:apply-templates mode="iiif" select="/" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">Could not find an adequate mode to transform the data.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="/" mode="iiif">
        <xsl:variable name="serviceJson" select="json-doc(ddblabs:normalizeUrl(string(//mets:mets/mets:fileSec/mets:fileGrp/mets:file[1][@MIMETYPE = 'application/vnd.kitodo.iiif']/mets:FLocat/@xlink:href)) || '/info.json')" />
        <xsl:variable name="serviceVersion">
            <xsl:choose>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/1/context.json'">ImageService1</xsl:when>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/2/context.json'">ImageService2</xsl:when>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/3/context.json'">ImageService3</xsl:when>
                <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="serviceProfileLevel">
            <xsl:choose>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/2/level1.json'">level1</xsl:when>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/2/level2.json'">level2</xsl:when>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/2/level3.json'">level3</xsl:when>
                <xsl:otherwise>unknown</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:map>
            <!-- "@context": "http://iiif.io/api/presentation/3/context.json" -->
            <xsl:map-entry key="'@context'" select="'http://iiif.io/api/presentation/3/context.json'" />
            <!-- "id": "https://www.deutsche-digitale-bibliothek.de/item/WYSPZ4UGJYOETW5F7EFHLR3GRQODFKCD" -->
            <xsl:map-entry key="'id'" select="$selfUrl" />
            <!-- "type": "Manifest", -->
            <xsl:map-entry key="'type'" select="'Manifest'" />
            <!-- 
            "label": {
              "de": [
                "Bergedorfer Zeitung und Anzeiger"
            ]},
            -->
            <xsl:map-entry key="'label'" select="
                    map {
                        'de': array {//mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:relatedItem/mods:titleInfo/mods:title/text()}
                    }" />
            <!--
            "thumbnail": [{
               "id": "https://iiif.deutsche-digitale-bibliothek.de/image/2/475edf69-a029-46cb-a165-c331a59e02a6/full/200,/0/default.jpg",
               "type": "Image",
               "format": "image/jpeg",
               "service": [{
                  "id": "https://iiif.deutsche-digitale-bibliothek.de/image/2/475edf69-a029-46cb-a165-c331a59e02a6",
                  "type": "ImageService2",
                  "profile": "level2"
               }]
            }],
            -->
            <xsl:map-entry key="'thumbnail'" select="
                    array {
                        map {
                            'id': ddblabs:normalizeUrl(string(//mets:mets/mets:fileSec/mets:fileGrp/mets:file[1][@MIMETYPE = 'application/vnd.kitodo.iiif']/mets:FLocat/@xlink:href)) || '/full/200,/0/default.jpg',
                            'type': 'Image',
                            'format': 'image/jpeg',
                            'service': array {
                                map {
                                    'id': string(//mets:mets/mets:fileSec/mets:fileGrp/mets:file[1][@MIMETYPE = 'application/vnd.kitodo.iiif']/mets:FLocat/@xlink:href),
                                    'type': $serviceVersion,
                                    'profile': $serviceProfileLevel
                                }
                            }
                        }
                    }" />
            <!--
            "viewingDirection": "left-to-right",
            -->
            <xsl:map-entry key="'viewingDirection'" select="'left-to-right'" />
            <!--
            "behavior": [ "individuals" ],
            -->
            <xsl:map-entry key="'behavior'" select="array {'individuals'}" />
            <!--
            "rights": "http://creativecommons.org/licenses/by-nc/4.0/",
            -->
            <xsl:map-entry key="'rights'" select="//mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:recordInfo/mods:recordInfoNote[@type = 'license']/text()" />
            <!-- 
            "requiredStatement": {
                "label": {
                    "en": [
                        "Attribution"
                        ],
                    "de": [
                        "Zuschreibung"
                    ]
                },
                "value": {
                    "none": [
                        "<a href=\"https://iserver.imm-hamburg.de/objekt_start.fau?prj=IMMH-Digita&dm=Datenbankname&ref=102719\" target=\"_blank\">Peter Tamm Sen. Stiftung</a>"
                    ]
                }
            },
            -->
            <xsl:map-entry key="'requiredStatement'" select="
                    map {
                        'label': map {
                            'en': array {'Attribution'},
                            'de': array {'Zuschreibung'}
                        },
                        'value': map {
                            'none': array {ddblabs:generateLink(//mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:originInfo/mods:publisher[1], //mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:identifier[@type = 'purl'][1], true())}
                        }
                    }" />
            <!-- provider -->
            <xsl:map-entry key="'provider'" select="array {ddblabs:generateProvider($providerId)}" />

            <!-- 
              "homepage": [
                {
                  "id": "https://www.deutsche-digitale-bibliothek.de/item/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO",
                  "type": "Text",
                  "label": {
                    "none": [
                      "Deutsche Digitale Bibliothek"
                    ]
                  },
                  "format": "text/html"
                }
              ],
            -->
            <xsl:map-entry key="'homepage'" select="
                    map {
                        'id': 'https://www.deutsche-digitale-bibliothek.de/item/' || $ddbId,
                        'type': 'Text',
                        'label': map {'none': array {'Deutsche Digitale Bibliothek'}},
                        'format': 'text/html'
                    }" />
            <!-- 
              "seeAlso": [
                {
                  "id": "https://api.deutsche-digitale-bibliothek.de/items/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO",
                  "type": "Dataset",
                  "format": "application/xml",
                  "profile": "https://www.deutsche-digitale-bibliothek.de/ns/cortex"
                }
              ]
            -->
            <xsl:map-entry key="'seeAlso'" select="
                    map {
                        'id': 'https://api.deutsche-digitale-bibliothek.de/items/' || $ddbId,
                        'type': 'Dataset',
                        'format': 'application/xml',
                        'profile': 'https://www.deutsche-digitale-bibliothek.de/ns/cortex'
                    }" />
            <!-- 
              "start": {
                "id": "https://labs.deutsche-digitale-bibliothek.de/iiif/presentation/3/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO/canvas/p1",
                "type": "Canvas"
              }
            -->
            <xsl:map-entry key="'start'" select="
                    map {
                        'id': $selfUrl || '/canvas/' || //mets:mets/mets:structMap/mets:div/mets:div[@ORDER = '1']/@ID,
                        'type': 'Canvas'
                    }" />

            <!-- 
              "structures": [
                {
                  "id": "https://labs.deutsche-digitale-bibliothek.de/iiif/presentation/3/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO/range/r0",
                  "type": "Range",
                  "label": {
                    "de": [
                      "Übersicht"
                    ],
                    "en": [
                      "Content"
                    ]
                  },
            -->
            <xsl:variable as="map(*)" name="structures">
                <xsl:map>
                    <xsl:map-entry key="'id'" select="$selfUrl || '/range/r0'" />
                    <xsl:map-entry key="'type'" select="'Range'" />
                    <xsl:map-entry key="'label'" select="
                            map {
                                'de': array {'Inhaltsbersicht'},
                                'en': array {'Table of Contents'}
                            }
                            " />
                    <xsl:apply-templates mode="iiif" select="//mets:mets/mets:structMap[@TYPE = 'LOGICAL']/mets:div" />
                </xsl:map>
            </xsl:variable>
            <xsl:map-entry key="'structures'" select="array {$structures}"> </xsl:map-entry>


            <!-- 
            "items": [
                {
                    "id": "https://labs.deutsche-digitale-bibliothek.de/iiif/presentation/3/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO/canvas/p1",
                    "type": "Canvas",
                    "label": {
                        "de": ["Auriga (1967), Frachtschiff, Argo Reederei Richard Adler & Söhne, Bremen, Bau-Nr. 1140"]
                    },
                    "height": 1155,
                    "width": 1732,
                    "items": [
                        {
                        ...
            -->
            <xsl:variable name="fileIds" select="//mets:mets/mets:fileSec/mets:fileGrp/mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']/@ID" />

            <xsl:variable as="map(*)*" name="items">
                <xsl:for-each select="//mets:mets/mets:structMap[@TYPE = 'PHYSICAL']/mets:div/mets:div">
                    <xsl:sort data-type="number" order="ascending" select="@order" />
                    <xsl:variable name="fileId" select="mets:fptr/@FILEID[. = $fileIds][1]" />

                    <xsl:map>
                        <xsl:map-entry key="'id'" select="$selfUrl || '/range/' || @ID" />
                        <xsl:map-entry key="'type'" select="'Canvas'" />
                        <xsl:map-entry key="'label'" select="
                                map {'de': array {('Meine Bildunterschrift')}}
                                " />
                        <xsl:map-entry key="'height'" select="600" />
                        <xsl:map-entry key="'width'" select="800" />
                        <xsl:map-entry key="'test'" select="array {data(//mets:mets/mets:fileSec/mets:fileGrp/mets:file[@ID = $fileId]/mets:FLocat/@xlink:href)}" />
                    </xsl:map>
                </xsl:for-each>
            </xsl:variable>
            <xsl:map-entry key="'items'" select="array {$items}"> </xsl:map-entry>
        </xsl:map>

    </xsl:template>
    <xsl:template as="map(*)" match="mets:div" mode="iiif">
        <xsl:param as="map(*)*" name="canvasItems" />
        <xsl:variable as="map(*)*" name="rangeItems">
            <xsl:map>
                <xsl:map-entry key="'id'" select="$selfUrl || '/range/' || string(@ID)" />
                <xsl:map-entry key="'type'" select="'Range'" />
                <xsl:choose>
                    <xsl:when test="@LABEL">
                        <xsl:map-entry key="'label'" select="string(@LABEL)" />
                    </xsl:when>
                    <xsl:when test="@ORDERLABEL">
                        <xsl:map-entry key="'label'" select="string(@LABEL)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:map-entry key="'label'" select="string(@LABEL)" />
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                    <xsl:when test="exists(mets:div)">
                        <xsl:apply-templates mode="iiif" select="mets:div">
                            <xsl:with-param as="map(*)*" name="canvasItems">
                                <xsl:apply-templates mode="iiif" select="//mets:mets/mets:structLink/mets:smLink[@xlink:from = current()/@ID]" />
                            </xsl:with-param>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:when test="exists(//mets:mets/mets:structLink/mets:smLink[@xlink:from = current()/@ID])">
                        <xsl:variable as="map(*)*" name="canvasItems">
                            <xsl:apply-templates mode="iiif" select="//mets:mets/mets:structLink/mets:smLink[@xlink:from = current()/@ID]" />
                        </xsl:variable>
                        <xsl:map-entry key="'items'" select="array {$canvasItems}" />
                    </xsl:when>
                    <xsl:otherwise />
                </xsl:choose>

            </xsl:map>
        </xsl:variable>

        <xsl:map-entry key="'items'">
            <xsl:variable as="array(*)" name="combinedArray">
                <!-- Erstelle ein temporäres Array, das nur nicht-leere Items enthält -->
                <xsl:sequence select="
                        array:join((
                        if (exists($rangeItems) and map:size($rangeItems) > 0) then
                            array {$rangeItems}
                        else
                            (),
                        if (exists($canvasItems)) then
                            array {$canvasItems}
                        else
                            ()
                        ))" />
            </xsl:variable>

            <!-- Prüfe, ob das kombinierte Array leer ist, um ein leeres Objekt zu vermeiden -->
            <xsl:sequence select="
                    if (array:size($combinedArray) > 0) then
                        $combinedArray
                    else
                        ()" />
        </xsl:map-entry>
    </xsl:template>

    <xsl:template as="map(*)" match="mets:smLink" mode="iiif">
        <xsl:map>
            <xsl:map-entry key="'id'" select="$selfUrl || '/canvas/' || string(@xlink:to)" />
            <xsl:map-entry key="'type'" select="'Canvas'" />
        </xsl:map>
    </xsl:template>

</xsl:stylesheet>
