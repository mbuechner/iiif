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
<xsl:stylesheet version="3.0" xmlns:array="http://www.w3.org/2005/xpath-functions/array" xmlns:cortex="http://www.deutsche-digitale-bibliothek.de/cortex" xmlns:ddblabs="https://labs.deutsche-digitale-bibliothek.de" xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:mets="http://www.loc.gov/METS/" xmlns:mix="http://www.loc.gov/mix/v20" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:oai="http://www.openarchives.org/OAI/2.0/" xmlns:saxon="http://saxon.sf.net/" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- <xsl:output encoding="UTF-8" indent="yes" method="json" saxon:property-order="@context id type label metadata summary requiredStatement rights provider items structures annotations thumbnail navDate homepage logo rendering seeAlso partOf start services" use-character-maps="no-escape-slash" /> -->
    <xsl:output encoding="UTF-8" indent="yes" method="json" use-character-maps="no-escape-slash" />
    <xsl:strip-space elements="*" />
    <xsl:character-map name="no-escape-slash">
        <xsl:output-character character="/" string="/" />
    </xsl:character-map>
    <!-- Global parameters (these should be set from outside) -->
    <xsl:param as="xs:string" name="itemId" select="'TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO'" />
    <xsl:param as="xs:string" name="itemUrl" select="'https://iiif.deutsche-digitale-bibliothek.de/presentation/3/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO'" />
    <xsl:param as="element(cortex:provider-info)" name="providerInfo">
        <cortex:provider-info>
            <cortex:provider-ddb-id>ABCDEFGHIJKLMNOPQRSTUVWXYZ012345</cortex:provider-ddb-id>
            <cortex:provider-name>MyProvider</cortex:provider-name>
            <cortex:provider-uri>https://www.example.org</cortex:provider-uri>
            <cortex:provider-logo>https://www.example.org/logo.jpg</cortex:provider-logo>
        </cortex:provider-info>
    </xsl:param>
    <xsl:variable as="xs:string" name="mode" select="
            if (exists(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']]))
            then
                'IIIF'
            else
                if (exists(/mets:mets/mets:fileSec/mets:fileGrp[mets:file/mets:FLocat[ends-with(@xlink:href, '/full/max/0/default.jpg') or ends-with(@xlink:href, '/full/full/0/default.jpg')]]))
                then
                    'IIIF'
                else
                    'DEFAULT'
            " />
    <xsl:variable as="xs:string" name="preferredFileGrp" select="
            if ($mode = 'IIIF' and string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']][1]/@USE))
            then
                string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']][1]/@USE)
            else
                if ($mode = 'IIIF' and string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file/mets:FLocat[ends-with(@xlink:href, '/full/max/0/default.jpg') or ends-with(@xlink:href, '/full/full/0/default.jpg')]][1]/@USE))
                then
                    string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file/mets:FLocat[ends-with(@xlink:href, '/full/max/0/default.jpg') or ends-with(@xlink:href, '/full/full/0/default.jpg')]][1]/@USE)
                else
                    if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'MAX'])) then
                        'MAX'
                    else
                        if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'DEFAULT'])) then
                            'DEFAULT'
                        else
                            'ERROR'" />
    <xsl:variable as="xs:string" name="preferredFileGrpForThumbnails" select="
            if ($mode = 'IIIF')
            then
                string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']][1]/@USE)
            else
                if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'THUMBS'])) then
                    'THUMBS'
                else
                    if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'MIN'])) then
                        'MIN'
                    else
                        if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'DEFAULT'])) then
                            'DEFAULT'
                        else
                            'ERROR'" />

    <xsl:function as="xs:string" name="ddblabs:normalize-url">
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
        <xsl:sequence select="replace(normalize-space($url), '/$', '')" />
    </xsl:function>
    <xsl:function as="xs:string" name="ddblabs:generate-link">
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
    <xsl:function as="xs:string" name="ddblabs:iiif-base-url">
        <xsl:param as="xs:string" name="url" />
        <xsl:variable as="xs:string" name="cleanUrl" select="ddblabs:normalize-url($url)" />
        <!-- 
            Gibt die Basis-URL eines IIIF Image API-Aufrufs zurück, d. h. die URL bis einschließlich Identifier.
            
            Funktion deckt folgende Fälle ab:
            1. URL endet mit /info.json → entfernt /info.json
            2. URL endet mit /.../default.format → entfernt region/size/rotation/default.format
            3. URL ist bereits die Basis mit Identifier → wird unverändert zurückgegeben
        -->
        <xsl:sequence select="
                if (ends-with($cleanUrl, '/info.json')) then
                    replace($cleanUrl, '/info\.json$', '')
                else
                    if (matches($cleanUrl, '/[^/]+/[^/]+/[^/]+/default\.\w+$')) then
                        replace($cleanUrl, '^(https?://[^/]+/[^/]+/.+?)/[^/]+/[^/]+/[^/]+/default\.\w+$', '$1')
                    else
                        $cleanUrl
                " />
    </xsl:function>
    <xsl:function as="map(*)" name="ddblabs:transform-div">
        <!--
            Funktion: fn:transform-div
            Beschreibung:
                Wandelt ein mets:div rekursiv in ein IIIF Range-Objekt um.
                Verlinkte PHYS-IDs aus structLink (xlink:to) werden als Canvas-Objekte
                in "items" eingefügt.
        
            Parameter:
                $div  – mets:div-Element
                $root – Wurzelknoten zur structLink-Auswertung
        
            Rückgabe:
                map(*) – IIIF Range mit id, type, label und items
        -->
        <xsl:param as="element(mets:div)" name="div" />
        <xsl:param as="document-node()" name="root" />

        <xsl:variable name="id" select="string($div/@ID)" />
        <xsl:variable name="label" select="($div/@LABEL, $div/@ORDERLABEL, $div/@ID)[. != ''][1]" />
        <xsl:variable name="targets" select="$root//mets:structLink/mets:smLink[@xlink:from = $id]/@xlink:to" />

        <xsl:variable name="child-divs" select="$div/mets:div" />

        <!-- Canvas-Verlinkungen aus structLink -->
        <xsl:variable as="array(*)" name="linked-canvases">
            <xsl:sequence select="
                    array {
                        for $t in $targets
                        return
                            map {
                                'id': $itemUrl || '/canvas/' || $t,
                                'type': 'Canvas'
                                (: optional: 'label': map { 'none': [string($label)] } :)
                            }
                    }
                    " />
        </xsl:variable>

        <!-- Kind-Elemente rekursiv behandeln -->
        <xsl:variable as="array(*)" name="child-items">
            <xsl:choose>
                <xsl:when test="exists($child-divs)">
                    <xsl:sequence select="
                            array {
                                for $child in $child-divs
                                return
                                    ddblabs:transform-div($child, $root)
                            }
                            " />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="[]" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Mische eigene Kind-Divs und Canvas-Links -->
        <xsl:variable name="all-items" select="
                if (exists($child-items) or exists($linked-canvases))
                then
                    array:join(($child-items, $linked-canvases))
                else
                    array {$itemUrl || '/range/' || $id}
                " />

        <xsl:sequence select="
                map {
                    'id': $itemUrl || '/range/' || $id,
                    'type': 'Range',
                    'label': map {'none': [string($label)]},
                    'items': $all-items
                }
                " />
    </xsl:function>
    <xsl:function as="map(*)" name="ddblabs:build-canvas">
        <!--
            Funktion: iiif:build-canvas
            Beschreibung:
                Baut ein vollständiges IIIF Canvas-Objekt aus einem mets:div in der PHYSICAL structMap.
            Parameter:
                $physDiv – <mets:div> mit TYPE="page"
                $root – Root-Dokument zur Auflösung von fileGrp, FLocat, amdSec
            Rückgabe:
        -->
        <xsl:param as="element(mets:div)" name="physDiv" />
        <xsl:param as="document-node()" name="root" />
        <xsl:param as="xs:integer" name="position" />

        <!-- IDs und URLs -->
        <xsl:variable name="physId" select="$physDiv/@ID" />

        <!-- Hole passende IIIF-Datei -->
        <!-- TODO (in IIIF verbessern) -->
        <xsl:variable name="iiifFile" select="$root/mets:mets/mets:fileSec//mets:fileGrp[@USE = $preferredFileGrp]/mets:file[@ID = /mets:mets/mets:structMap/mets:div/mets:div[@ID = $physId]/mets:fptr/@FILEID]" />
        <xsl:variable name="fileId" select="string($iiifFile/@ID)" />
        <xsl:variable name="fileUrl" select="string($iiifFile/mets:FLocat/@xlink:href)" />
        <xsl:variable name="mimeType" select="string($iiifFile/@MIMETYPE)" />
        <xsl:variable name="thumbnailUrl" select="
                if (exists($root/mets:mets/mets:fileSec//mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[@ID = /mets:mets/mets:structMap/mets:div/mets:div[@ID = 'phys14754105']/mets:fptr/@FILEID]/mets:FLocat/@xlink:href))
                then
                    string($root/mets:mets/mets:fileSec//mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[@ID = /mets:mets/mets:structMap/mets:div/mets:div[@ID = 'phys14754105']/mets:fptr/@FILEID]/mets:FLocat/@xlink:href)
                else
                    $fileUrl
                " />
        <xsl:variable name="thumbnailMimeType" select="
                if (exists($root/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[@ID = $fileId]/@MIMETYPE))
                then
                    string($root/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[@ID = $fileId]/@MIMETYPE)
                else
                    $mimeType
                " />

        <!-- Bilddimensionen -->
        <xsl:variable name="mix" select="$root/mets:mets/mets:amdSec/mets:techMD[@ID = string($iiifFile/@ADMID)]/mets:mdWrap/mets:xmlData/mix:mix/mix:BasicImageInformation/mix:BasicImageCharacteristics" />
        <xsl:variable as="xs:integer" name="width" select="
                if ($mix/mix:imageWidth/text()) then
                    xs:integer($mix/mix:imageWidth)
                else
                    800" />
        <xsl:variable as="xs:integer" name="height" select="
                if ($mix/mix:imageHeight/text()) then
                    xs:integer($mix/mix:imageHeight)
                else
                    600" />

        <!-- Volltexte holen -->
        <xsl:variable as="xs:string" name="fileId" select="string($root/mets:mets/mets:structMap/mets:div/mets:div[@ID = $physId]/mets:fptr[contains(@FILEID, 'DDB_FULLTEXT')]/@FILEID)" />
        <xsl:variable as="xs:string" name="fulltextUrl" select="
                if ($fileId != '')
                then
                    string($root/mets:mets/mets:fileSec//mets:fileGrp[@USE = 'DDB_FULLTEXT']/mets:file[@ID = $fileId]/mets:FLocat/@xlink:href)
                else
                    ''" />

        <!-- Zusammensetzen des Canvas-Objekts -->
        <xsl:sequence select="
                map:merge((
                map {
                    'id': $itemUrl || '/canvas/' || $physId,
                    'type': 'Canvas',
                    'height': $height,
                    'width': $width,
                    'items': [
                        map {
                            'id': $itemUrl || '/canvas/' || $physId || '/1',
                            'type': 'AnnotationPage',
                            'items': [
                                map {
                                    'id': $itemUrl || '/canvas/' || $physId || '/annotation/1',
                                    'type': 'Annotation',
                                    'motivation': 'painting',
                                    'body': map {
                                        'id': $fileUrl,
                                        'type': 'Image',
                                        'format': $mimeType,
                                        'height': $height,
                                        'width': $width
                                    },
                                    'target': $itemUrl || '/canvas/' || $physId
                                }
                            ]
                        }
                    ],
                    'label': map {
                        'none': [
                            if (string-length(normalize-space($physDiv/@ORDERLABEL)) > 0)
                            then
                                string($physDiv/@ORDERLABEL)
                            else
                                string($position)
                        ]
                    },
                    'thumbnail': [
                        map {
                            'id': $thumbnailUrl,
                            'type': 'Image',
                            'format': $thumbnailMimeType
                        }
                    ]
                },
                if ($fulltextUrl != '')
                then
                    map {
                        'rendering': [
                            map {
                                'id': $fulltextUrl,
                                'type': 'Text',
                                'format': 'application/xml',
                                'profile': 'http://www.loc.gov/standards/alto/',
                                'label': map {'none': ['ALTO XML']}
                            }
                        ]
                    }
                else
                    ()
                ))
                " />
    </xsl:function>
    <xsl:function as="map(*)" name="ddblabs:build-iiif-canvas">
        <!--
            Funktion: iiif:build-iiif-canvas
            Beschreibung:
                Baut ein vollständiges IIIF Canvas-Objekt aus einem mets:div in der PHYSICAL structMap.
            Parameter:
                $physDiv – <mets:div> mit TYPE="page"
                $root – Root-Dokument zur Auflösung von fileGrp, FLocat, amdSec
            Rückgabe:
                map(*) – Ein IIIF-Canvas inklusive AnnotationPage, Annotation, Bildinformationen und Service
        -->
        <xsl:param as="element(mets:div)" name="physDiv" />
        <xsl:param as="document-node()" name="root" />
        <xsl:param as="xs:string" name="serviceVersion" />
        <xsl:param as="xs:string" name="serviceProfileLevel" />
        <xsl:param as="xs:integer" name="position" />

        <!-- IDs und URLs -->
        <xsl:variable name="physId" select="$physDiv/@ID" />

        <!-- Hole passende IIIF-Datei -->
        <xsl:variable name="iiifFile" select="$root/mets:mets/mets:fileSec//mets:fileGrp[@USE = $preferredFileGrp]/mets:file[@ID = /mets:mets/mets:structMap/mets:div/mets:div[@ID = $physId]/mets:fptr/@FILEID]" />
        <xsl:variable name="fileId" select="string($iiifFile/@ID)" />
        <xsl:variable name="baseUrl" select="ddblabs:iiif-base-url(string($iiifFile/mets:FLocat/@xlink:href))" />

        <!-- Bilddimensionen -->
        <xsl:variable name="mix" select="$root/mets:mets/mets:amdSec/mets:techMD[@ID = string($iiifFile/@ADMID)]/mets:mdWrap/mets:xmlData/mix:mix/mix:BasicImageInformation/mix:BasicImageCharacteristics" />
        <xsl:variable name="width" select="
                if ($mix/mix:imageWidth/text()) then
                    xs:integer($mix/mix:imageWidth)
                else
                    800" />
        <xsl:variable name="height" select="
                if ($mix/mix:imageHeight/text()) then
                    xs:integer($mix/mix:imageHeight)
                else
                    600" />

        <!-- Suffix -->
        <xsl:variable name="urlSuffix" select="
                if ($serviceVersion = '3')
                then
                    '/full/max/0/default.jpg'
                else
                    '/full/full/0/default.jpg'
                " />

        <!-- Volltexte holen -->
        <xsl:variable as="xs:string" name="fileId" select="string($root/mets:mets/mets:structMap/mets:div/mets:div[@ID = $physId]/mets:fptr[contains(@FILEID, 'DDB_FULLTEXT')]/@FILEID)" />
        <xsl:variable as="xs:string" name="fulltextUrl" select="
                if ($fileId != '')
                then
                    string($root/mets:mets/mets:fileSec//mets:fileGrp[@USE = 'DDB_FULLTEXT']/mets:file[@ID = $fileId]/mets:FLocat/@xlink:href)
                else
                    ''" />

        <!-- Zusammensetzen des Canvas-Objekts -->
        <xsl:sequence select="
                map:merge((map {
                    'id': $itemUrl || '/canvas/' || $physId,
                    'type': 'Canvas',
                    'height': $height,
                    'width': $width,
                    'items': [
                        map {
                            'id': $itemUrl || '/canvas/' || $physId || '/1',
                            'type': 'AnnotationPage',
                            'items': [
                                map {
                                    'id': $itemUrl || '/canvas/' || $physId || '/annotation/1',
                                    'type': 'Annotation',
                                    'motivation': 'painting',
                                    'body': map {
                                        'id': $baseUrl || $urlSuffix,
                                        'type': 'Image',
                                        'format': 'image/jpeg',
                                        'service': [
                                            map {
                                                'id': $baseUrl,
                                                'type': 'ImageService' || $serviceVersion,
                                                'profile': $serviceProfileLevel
                                            }
                                        ],
                                        'height': $height,
                                        'width': $width
                                    },
                                    'target': $itemUrl || '/canvas/' || $physId
                                }
                            ]
                        }
                    ],
                    'label': map {
                        'none': [
                            if (string-length(normalize-space($physDiv/@ORDERLABEL)) > 0)
                            then
                                string($physDiv/@ORDERLABEL)
                            else
                                string($position)
                        ]
                    },
                    'thumbnail': [
                        map {
                            'id': $baseUrl || '/full/!300,300/0/default.jpg',
                            'type': 'Image',
                            'format': 'image/jpeg',
                            'service': [
                                map {
                                    'id': $baseUrl,
                                    'type': 'ImageService' || $serviceVersion,
                                    'profile': $serviceProfileLevel
                                }
                            ]
                        }
                    ]
                },
                if ($fulltextUrl != '')
                then
                    map {
                        'rendering': [
                            map {
                                'id': $fulltextUrl,
                                'type': 'Text',
                                'format': 'application/xml',
                                'profile': 'http://www.loc.gov/standards/alto/',
                                'label': map {'none': ['ALTO XML']}
                            }
                        ]
                    }
                else
                    ()
                ))
                " />
    </xsl:function>
    <xsl:template match="/">
        <xsl:message select="'Start to transform ID ' || $itemId" />
        <xsl:choose>
            <xsl:when test="$mode = 'IIIF'">
                <xsl:apply-templates mode="iiif" select="/" />
            </xsl:when>
            <xsl:when test="$mode = 'DEFAULT'">
                <xsl:apply-templates mode="default" select="/" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message error-code="501" terminate="yes">
                    <xsl:value-of select="'Could not find an adequate mode to transform the data.'" />
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="/" mode="common">
        <!-- "@context": "http://iiif.io/api/presentation/3/context.json" -->
        <xsl:map-entry key="'@context'" select="'http://iiif.io/api/presentation/3/context.json'" />
        <!-- "id": "https://www.deutsche-digitale-bibliothek.de/item/WYSPZ4UGJYOETW5F7EFHLR3GRQODFKCD" -->
        <xsl:map-entry key="'id'" select="$itemUrl" />
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
                    'de': array {/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:relatedItem/mods:titleInfo/mods:title/text()}
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
        <xsl:map-entry key="'rights'" select="string(/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:recordInfo/mods:recordInfoNote[@type = 'license'])" />

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
                        'none': array {
                            ddblabs:generate-link(
                            if (exists(/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:originInfo[@eventType = 'digitization']))
                            then
                                string(/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:originInfo[@eventType = 'digitization']/mods:publisher[1])
                            else
                                string(/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:originInfo[not(@eventType)][1]/mods:publisher[1]),
                            
                            /mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods/mods:identifier[@type = 'purl'][1], true())
                        }
                    }
                }" />

        <!-- provider -->
        <!-- 
          "provider": {
            "id": "https://www.deutsche-digitale-bibliothek.de/organization/ABCDEFGHIJKLMNOPQRSTUVWXYZ012345",
            "type": "Agent",
            "label": { "none":[ "MyProvider" ] },
            "homepage": [ {
                "id": "https://www.example.org",
                "type": "Text",
                "label": { "none":[ "MyProvider" ] },
                "format": "text/html"
              } ],
            "logo": [ {
                "id": "https://www.example.org/logo.jpg",
                "type": "Image",
                "format": "image/jpeg",
                "height": 600,
                "width": 800
              } ],
            "seeAlso": [ {
                "id": "https://www.deutsche-digitale-bibliothek.de/organization/ABCDEFGHIJKLMNOPQRSTUVWXYZ012345",
                "type": "Text",
                "label": { "de":[ "MyProvider bei der Deutschen Digitalen Bibliothek" ] }
              } ]
          },
        -->
        <xsl:map-entry key="'provider'">
            <xsl:sequence select="
                    array {
                        map:merge((
                        map {
                            'id': 'https://www.deutsche-digitale-bibliothek.de/organization/' || string($providerInfo/cortex:provider-ddb-id),
                            'type': 'Agent',
                            'label': map {
                                'none': array {string($providerInfo/cortex:provider-name)}
                            }
                        },
                        map {
                            'seeAlso': array {
                                map {
                                    'id': 'https://www.deutsche-digitale-bibliothek.de/organization/' || string($providerInfo/cortex:provider-ddb-id),
                                    'type': 'Text',
                                    'label': map {
                                        'de': array {string($providerInfo/cortex:provider-name) || ' bei der Deutschen Digitalen Bibliothek'}
                                    }
                                }
                            }
                        },
                        if (string($providerInfo/cortex:provider-logo)) then
                            map {
                                'logo': array {
                                    map {
                                        'id': string($providerInfo/cortex:provider-logo),
                                        'type': 'Image',
                                        'width': 800,
                                        'height': 600,
                                        'format':
                                        if (matches($providerInfo/cortex:provider-logo, '\.jpe?g$', 'i')) then
                                            'image/jpeg'
                                        else
                                            if (ends-with(lower-case($providerInfo/cortex:provider-logo), '.png')) then
                                                'image/png'
                                            else
                                                'application/octet-stream'
                                    }
                                }
                            }
                        else
                            (),
                        if (string($providerInfo/cortex:provider-uri) and string($providerInfo/cortex:provider-name)) then
                            map {
                                'homepage': array {
                                    map {
                                        'id': string($providerInfo/cortex:provider-uri),
                                        'type': 'Text',
                                        'label': map {
                                            'none': array {string($providerInfo/cortex:provider-name)}
                                        },
                                        'format': 'text/html'
                                    }
                                }
                            }
                        else
                            ()
                        ))
                    }
                    " />
        </xsl:map-entry>

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
                array {
                    map {
                        'id': 'https://www.deutsche-digitale-bibliothek.de/item/' || $itemId,
                        'type': 'Text',
                        'label': map {
                            'de': array {'Deutsche Digitale Bibliothek'},
                            'en': array {'German Digitale Library'}
                        },
                        'format': 'text/html'
                    }
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
                array {
                    map {
                        'id': 'https://api.deutsche-digitale-bibliothek.de/2/items/' || $itemId,
                        'type': 'Dataset',
                        'format': 'application/xml',
                        'profile': 'https://www.deutsche-digitale-bibliothek.de/ns/cortex'
                    }
                }" />
        <!-- 
              "start": {
                "id": "https://labs.deutsche-digitale-bibliothek.de/iiif/presentation/3/TTNVQWVXY3AKILUHHULXB5H2ZHZGEKOO/canvas/p1",
                "type": "Canvas"
              }
            -->
        <xsl:map-entry key="'start'" select="
                map {
                    'id': $itemUrl || '/canvas/' || /mets:mets/mets:structMap[@TYPE = 'PHYSICAL']/mets:div/mets:div[@ORDER = '1']/@ID,
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
        <xsl:map-entry key="'structures'" select="
                array {
                    for $div in //mets:structMap[@TYPE = 'LOGICAL']/mets:div
                    return
                        ddblabs:transform-div($div, .)
                }
                " />
    </xsl:template>
    <xsl:template match="/" mode="default">
        <xsl:map>
            <xsl:apply-templates mode="common" select="." />
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
                            'id': string(/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[1]/mets:FLocat/@xlink:href),
                            'type': 'Image',
                            'format': string(/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrpForThumbnails]/mets:file[1]/@MIMETYPE),
                            'height': 600,
                            'width': 800
                        }
                    }" />

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
            <xsl:variable name="divs" select="/mets:mets/mets:structMap[@TYPE = 'PHYSICAL']/mets:div/mets:div" />
            <xsl:map-entry key="'items'" select="
                    array {
                        for $i in 1 to count($divs)
                        return
                            ddblabs:build-canvas($divs[$i], ., $i)
                    }
                    " />
        </xsl:map>
    </xsl:template>
    <xsl:template match="/" mode="iiif">
        <xsl:variable name="firstImageUrl" select="ddblabs:iiif-base-url(string(/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrp]/mets:file[1]/mets:FLocat/@xlink:href))" />
        <xsl:variable name="serviceJson" select="json-doc($firstImageUrl || '/info.json')" />
        <xsl:variable name="serviceVersion">
            <xsl:choose>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/1/context.json'">1</xsl:when>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/2/context.json'">2</xsl:when>
                <xsl:when test="map:get($serviceJson, '@context') = 'http://iiif.io/api/image/3/context.json'">3</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="serviceProfileLevel">
            <xsl:choose>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/' || $serviceVersion || '/level1.json'">level1</xsl:when>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/' || $serviceVersion || '/level2.json'">level2</xsl:when>
                <xsl:when test="$serviceJson?profile?*[1] = 'http://iiif.io/api/image/' || $serviceVersion || '/level3.json'">level3</xsl:when>
                <xsl:otherwise>level0</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:map>
            <xsl:apply-templates mode="common" select="." />
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
            <xsl:variable as="xs:string" name="thumb" select="ddblabs:iiif-base-url(string(/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrpForThumbnails][1]/mets:file[1]/mets:FLocat/@xlink:href))" />
            <xsl:map-entry key="'thumbnail'" select="
                    array {
                        map {
                            'id': $thumb || '/full/!300,300/0/default.jpg',
                            'type': 'Image',
                            'format': 'image/jpeg',
                            'service': array {
                                map {
                                    'id': $thumb,
                                    'type': 'ImageService' || $serviceVersion,
                                    'profile': $serviceProfileLevel
                                }
                            }
                        }
                    }" />

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
            <xsl:variable name="divs" select="//mets:structMap[@TYPE = 'PHYSICAL']//mets:div[@TYPE = 'page']" />
            <xsl:map-entry key="'items'" select="
                    array {
                        for $i in 1 to count($divs)
                        return
                            ddblabs:build-iiif-canvas($divs[$i], ., $serviceVersion, $serviceProfileLevel, $i)
                    }
                    " />
        </xsl:map>
    </xsl:template>
</xsl:stylesheet>
