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

    <!--
        Keys definieren für schnelle Lookups
          - fileGrpByUse: Zugriff auf mets:fileGrp nach @USE
          - fileByID: Zugriff auf mets:file nach @ID
          - linkByFrom: Zugriff auf structLink smLink nach xlink:from
    -->
    <xsl:key match="mets:fileGrp" name="fileGrpByUse" use="@USE" />
    <xsl:key match="mets:file" name="fileByID" use="@ID" />
    <xsl:key match="mets:smLink" name="linkByFrom" use="@xlink:from" />
    <xsl:key match="mets:div" name="divByID" use="@ID" />

    <!-- Global Variables -->
    <xsl:variable as="xs:integer" name="thumbnailWidth" select="600" />
    <xsl:variable as="document-node()" name="root" select="/" />
    <xsl:variable as="element(mets:fileSec)" name="fileSec" select="/mets:mets/mets:fileSec" />
    <xsl:variable as="element(mets:structMap)" name="structMapPhysical" select="/mets:mets/mets:structMap[@TYPE = 'PHYSICAL']" />
    <xsl:variable as="element(mets:amdSec)" name="amdSec" select="/mets:mets/mets:amdSec" />
    <xsl:variable as="element(mets:div)*" name="allPageDivs" select="$structMapPhysical/mets:div/mets:div[@TYPE = 'page']" />

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
            if ($mode = 'IIIF' and string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']][1]/@USE))
            then
                string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file[@MIMETYPE = 'application/vnd.kitodo.iiif']][1]/@USE)
            else
                if ($mode = 'IIIF' and string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file/mets:FLocat[ends-with(@xlink:href, '/full/max/0/default.jpg') or ends-with(@xlink:href, '/full/full/0/default.jpg')]][1]/@USE))
                then
                    string(/mets:mets/mets:fileSec/mets:fileGrp[mets:file/mets:FLocat[ends-with(@xlink:href, '/full/max/0/default.jpg') or ends-with(@xlink:href, '/full/full/0/default.jpg')]][1]/@USE)
                else
                    if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'MIN'])) then
                        'MIN'
                    else
                        if (exists(/mets:mets/mets:fileSec/mets:fileGrp[@USE = 'DEFAULT'])) then
                            'DEFAULT'
                        else
                            'ERROR'" />

    <!--
       Funktion: ddblabs:normalizeUrl
       Beschreibung: Entfernt den abschließenden Schrägstrich von einer URL, falls vorhanden.
       Parameter:
           $url (xs:string) - Die URL, die normiert werden soll.
       Rückgabewert: xs:string - Die normierte URL ohne abschließenden Schrägstrich.
       Beispiel:
           ddblabs:normalizeUrl('http://example.com/') gibt 'http://example.com' zurück.
     -->
    <xsl:function as="xs:string" name="ddblabs:normalize-url">

        <xsl:param as="xs:string" name="url" />
        <xsl:sequence select="replace(normalize-space($url), '/$', '')" />
    </xsl:function>

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
    <xsl:function as="xs:string" name="ddblabs:generate-link">
        <xsl:param as="xs:string" name="text" />
        <xsl:param as="xs:string?" name="url" />
        <xsl:param as="xs:boolean?" name="blank" />

        <xsl:variable name="safeUrl" select="
                if (ddblabs:normalize-url(string($url)) = '') then
                    ''
                else
                    ddblabs:normalize-url(string($url))" />
        <xsl:variable name="safeBlank" select="boolean($blank)" />

        <xsl:variable name="targetAttr" select="
                if ($safeBlank) then
                    ' target=&quot;_blank&quot;'
                else
                    ''" />
        <xsl:sequence select="
                if (not($safeUrl)) then
                    string($text)
                else
                    concat('&lt;a href=&quot;', $safeUrl, '&quot;', $targetAttr, '&gt;', string($text), '&lt;/a&gt;')
                " />
    </xsl:function>

    <!-- 
        Gibt die Basis-URL eines IIIF Image API-Aufrufs zurück, d. h. die URL bis einschließlich Identifier.
        
        Funktion deckt folgende Fälle ab:
        1. URL endet mit /info.json → entfernt /info.json
        2. URL endet mit /.../default.format → entfernt region/size/rotation/default.format
        3. URL ist bereits die Basis mit Identifier → wird unverändert zurückgegeben
    -->
    <xsl:function as="xs:string" name="ddblabs:iiif-base-url">
        <xsl:param as="xs:string" name="url" />
        <xsl:variable as="xs:string" name="cleanUrl" select="ddblabs:normalize-url($url)" />

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

    <!--
        Funktion gibt optional eine Map zurück:
          – Map mit den Werten, wenn alles erfolgreich extrahiert wurde
          – ansonsten die leere Sequenz ()
    -->
    <xsl:function as="map(xs:string,item()?)?" name="ddblabs:get-info">
        <xsl:param as="xs:string" name="url" />

        <xsl:try>
            <!-- 0) rohen JSON-Text holen -->
            <xsl:variable name="raw" select="unparsed-text($url)" />

            <!-- 1) JSON parsen -->
            <xsl:variable name="info" select="parse-json($raw)" />

            <!-- API-Verion -->
            <xsl:variable name="version">
                <xsl:choose>
                    <xsl:when test="$info?('@context') = 'http://iiif.io/api/image/1/context.json'">1</xsl:when>
                    <xsl:when test="$info?('@context') = 'http://iiif.io/api/image/2/context.json'">2</xsl:when>
                    <xsl:when test="$info?('@context') = 'http://iiif.io/api/image/3/context.json'">3</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <!-- 3) nur die String-Einträge aus profile nehmen -->
            <xsl:variable name="profiles" select="
                    $info?profile?*[
                    . instance of xs:string
                    and matches(., '^.*level([0-9])+(\.json)?$')
                    ]
                    " />

            <!-- 4) Abbruch, falls Felder fehlen -->
            <xsl:choose>
                <xsl:when test="
                        exists($info?('@context'))
                        and exists($info?width)
                        and exists($info?height)
                        and exists($profiles)
                        and exists($version)
                        ">
                    <!-- 5) Paare aus Name+lvl bauen -->
                    <xsl:variable as="map(xs:string,item())*" name="pairs">
                        <xsl:for-each select="$profiles">
                            <xsl:variable name="lvl" select="xs:integer(replace(., '^.*level([0-9])+(\.json)?$', '$1'))" />
                            <xsl:sequence select="
                                    map {
                                        'name': .,
                                        'lvl': $lvl
                                    }
                                    " />
                        </xsl:for-each>
                    </xsl:variable>

                    <!-- 6) höchstes Level finden und Namen extrahieren -->
                    <xsl:variable name="max-lvl" select="max($pairs ! map:get(., 'lvl'))" />
                    <xsl:variable name="best" select="$pairs[map:get(., 'lvl') = $max-lvl] ! map:get(., 'name')" />

                    <!-- 7) Ergebnis-Map zurückgeben -->
                    <xsl:sequence select="
                            map {
                                'context': $info?('@context'),
                                'version': $version,
                                'width': $info?width,
                                'height': $info?height,
                                'profile': $best
                            }
                            " />
                </xsl:when>
                <xsl:otherwise>
                    <!-- falls Daten unvollständig sind -->
                    <xsl:sequence select="()" />
                </xsl:otherwise>
            </xsl:choose>

            <xsl:catch>
                <!-- bei jedem Fehler einfach leer zurückgeben -->
                <xsl:sequence select="()" />
            </xsl:catch>
        </xsl:try>
    </xsl:function>

    <!--
        img:scale:
          @origW und @origH: Originalbreite/-höhe
          entweder @newW ODER @newH angeben (das jeweils andere weglassen oder auf 0 setzen)
          liefert ein <dim width="…" height="…"/>
    -->
    <xsl:function as="map(xs:string,item()?)?" name="ddblabs:imageScale">
        <xsl:param as="xs:double" name="origW" />
        <xsl:param as="xs:double" name="origH" />
        <xsl:param as="xs:double" name="newW" />
        <xsl:param as="xs:double" name="newH" />

        <!-- Skalierungsfaktor ermitteln -->
        <xsl:variable name="factor" select="
                if ($newW &gt; 0) then
                    ($newW div $origW)
                else
                    ($newH div $origH)
                " />

        <!-- Neue Maße berechnen und runden -->
        <xsl:variable name="w" select="xs:integer(round($origW * $factor))" />
        <xsl:variable name="h" select="xs:integer(round($origH * $factor))" />

        <xsl:sequence select="
                map {
                    'width': $w,
                    'height': $h
                }
                " />
    </xsl:function>

    <!--
        Funktion: ddblabs:build-canvas
        Beschreibung:
          Baut ein vollständiges Canvas-Objekt aus einem <mets:div> mit TYPE="page" innerhalb der PHYSICAL structMap.
    
        Parameter:
          - $physDiv   (element(mets:div)): METS-Oberklasse für die Seite
          - $position  (xs:integer): Laufende Nummer der Seite für Label-Fallback
    
        Rückgabe:
          map(*) – Eine Map, die alle erforderlichen Felder des Canvas enthält.
    -->
    <xsl:function as="map(*)" name="ddblabs:build-canvas">

        <xsl:param as="element(mets:div)" name="physDiv" />
        <xsl:param as="xs:integer" name="position" />

        <!-- Subtrees cachen -->
        <xsl:variable name="physId" select="$physDiv/@ID" />

        <!-- IIIF-File holen via Keys -->
        <xsl:variable name="grpIIIF" select="key('fileGrpByUse', $preferredFileGrp, $fileSec)" />
        <xsl:variable name="physDiv" select="key('divByID', $physId, $structMapPhysical)" />
        <xsl:variable name="fptrID" select="$physDiv/mets:fptr/@FILEID" />
        <xsl:variable name="iiifFile" select="key('fileByID', $fptrID, $grpIIIF)" />
        <xsl:variable name="fileUrl" select="string($iiifFile/mets:FLocat/@xlink:href)" />
        <xsl:variable name="mimeType" select="string($iiifFile/@MIMETYPE)" />

        <!-- Bilddimensionen aus MIX -->
        <xsl:variable name="mix" select="$amdSec/mets:techMD[@ID = string($iiifFile/@ADMID)]/mets:mdWrap/mets:xmlData/mix:mix/mix:BasicImageInformation/mix:BasicImageCharacteristics" />
        <xsl:variable as="xs:integer" name="width" select="
                if ($mix/mix:imageWidth) then
                    xs:integer($mix/mix:imageWidth)
                else
                    1600" />
        <xsl:variable as="xs:integer" name="height" select="
                if ($mix/mix:imageHeight) then
                    xs:integer($mix/mix:imageHeight)
                else
                    1200" />

        <!-- Thumbnail via Keys + Fallback -->
        <xsl:variable name="grpThumb" select="key('fileGrpByUse', $preferredFileGrpForThumbnails, $fileSec)" />
        <xsl:variable name="physDiv" select="key('divByID', $physId, $structMapPhysical)" />
        <xsl:variable name="thumbID" select="$physDiv/mets:fptr[@USE = 'THUMBNAIL']/@FILEID" />
        <xsl:variable name="thumbFile" select="key('fileByID', $thumbID, $grpThumb)" />
        <xsl:variable as="xs:string" name="thumbnailUrl" select="
                if (exists($thumbFile/mets:FLocat/@xlink:href))
                then
                    string($thumbFile/mets:FLocat/@xlink:href)
                else
                    $fileUrl
                " />
        <xsl:variable as="xs:string" name="thumbnailMimeType" select="
                if (exists($thumbFile/@MIMETYPE))
                then
                    string($thumbFile/@MIMETYPE)
                else
                    $mimeType
                " />

        <!-- Volltext-URL holen, falls vorhanden -->
        <xsl:variable name="physDiv" select="key('divByID', $physId, $structMapPhysical)" />
        <xsl:variable name="fulltextFptr" select="$physDiv/mets:fptr[contains(@FILEID, 'DDB_FULLTEXT')]/@FILEID" />
        <xsl:variable as="xs:string" name="fulltextUrl" select="
                if ($fulltextFptr)
                then
                    string(
                    key('fileByID', $fulltextFptr,
                    key('fileGrpByUse', 'DDB_FULLTEXT', $fileSec))
                    /mets:FLocat/@xlink:href
                    )
                else
                    ''
                " />

        <xsl:variable as="xs:string" name="order" select="normalize-space($physDiv/@ORDER)" />
        <xsl:variable as="xs:string" name="orderLabel" select="normalize-space($physDiv/@ORDERLABEL)" />
        <xsl:variable as="xs:string" name="displayLabel" select="
                if ($order)
                then
                    concat(
                    $order,
                    if ($orderLabel)
                    then
                        concat(' (', $orderLabel, ')')
                    else
                        ()
                    )
                else
                    ($orderLabel, $position)[1]
                " />

        <!-- Canvas-Map zusammenbauen -->
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
                        'none': [$displayLabel]
                    },
                    'thumbnail': [
                        map {
                            'id': $thumbnailUrl,
                            'type': 'Image',
                            'format': $thumbnailMimeType
                        }
                    ]
                },
                if (string-length(normalize-space($fulltextUrl)) > 0)
                then
                    map {
                        'seeAlso': [
                            map {
                                'id': $fulltextUrl,
                                'type': 'Dataset',
                                'format': 'application/xml+alto',
                                'profile': 'http://www.loc.gov/standards/alto/'
                            }
                        ]
                    }
                else
                    map {}
                ))
                " />
    </xsl:function>

    <!--
        Funktion: ddblabs:build-iiif-canvas
        Beschreibung:
          Baut ein vollständiges IIIF Canvas-Objekt mit Service-Info aus einem <mets:div> in der PHYSICAL structMap.
    
        Parameter:
          - $physDiv           (element(mets:div)): METS-Oberklasse für die Seite
          - $position          (xs:integer): Laufende Nummer der Seite für Label-Fallback
          - $serviceVersion    (xs:string): IIIF-Service-Version ('2' oder '3')
          - $serviceProfileLevel(xs:string): IIIF-Service-Profil-URI
    
        Rückgabe:
          map(*) – Eine Map mit IIIF-Links, die alle erforderlichen Felder des Canvas enthält.
    -->
    <xsl:function as="map(*)" name="ddblabs:build-iiif-canvas">
        <xsl:param as="element(mets:div)" name="physDiv" />
        <xsl:param as="xs:integer" name="position" />

        <!-- 2) Subtrees cachen -->
        <xsl:variable name="physId" select="$physDiv/@ID" />

        <!-- IIIF-File via Keys -->
        <xsl:variable name="grpIIIF" select="key('fileGrpByUse', $preferredFileGrp, $fileSec)" />
        <xsl:variable name="physDiv" select="key('divByID', $physId, $structMapPhysical)" />
        <xsl:variable name="fptrID" select="$physDiv/mets:fptr/@FILEID" />
        <xsl:variable name="iiifFile" select="key('fileByID', $fptrID, $grpIIIF)" />
        <xsl:variable name="baseUrl" select="ddblabs:iiif-base-url(string($iiifFile/mets:FLocat/@xlink:href))" />

        <!-- Bilddimensionen aus info.json -->
        <xsl:variable name="info" select="ddblabs:get-info($baseUrl || '/info.json')" />

        <!-- Thumbnail-Größe berechnen -->
        <xsl:variable name="thumbnailDimension" select="ddblabs:imageScale($info?width, $info?height, $thumbnailWidth, 0)" />

        <!-- IIIF-URL Suffix -->
        <xsl:variable name="urlSuffix" select="
                if ($info?version = '3')
                then
                    '/full/max/0/default.jpg'
                else
                    '/full/full/0/default.jpg'" />

        <!-- Volltext-URL holen, falls vorhanden -->
        <xsl:variable name="physDiv" select="key('divByID', $physId, $structMapPhysical)" />
        <xsl:variable name="fulltextFptr" select="$physDiv/mets:fptr[contains(@FILEID, 'DDB_FULLTEXT')]/@FILEID" />
        <xsl:variable as="xs:string" name="fulltextUrl" select="
                if ($fulltextFptr)
                then
                    string(
                    key('fileByID', $fulltextFptr, key('fileGrpByUse', 'DDB_FULLTEXT', $fileSec))
                    /mets:FLocat/@xlink:href)
                else
                    ''" />

        <xsl:variable as="xs:string" name="order" select="normalize-space($physDiv/@ORDER)" />
        <xsl:variable as="xs:string" name="orderLabel" select="normalize-space($physDiv/@ORDERLABEL)" />
        <xsl:variable as="xs:string" name="displayLabel" select="
                if ($order)
                then
                    concat(
                    $order,
                    if ($orderLabel)
                    then
                        concat(' (', $orderLabel, ')')
                    else
                        ()
                    )
                else
                    ($orderLabel, $position)[1]
                " />

        <!-- Canvas-Map mit IIIF-Service zusammenbauen -->
        <xsl:sequence select="
                map:merge((
                map {
                    'id': $itemUrl || '/canvas/' || $physId,
                    'type': 'Canvas',
                    'height': $info?height,
                    'width': $info?width,
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
                                                'type': 'ImageService' || $info?version,
                                                'profile': $info?profile
                                            }
                                        ],
                                        'height': $info?height,
                                        'width': $info?width
                                    },
                                    'target': $itemUrl || '/canvas/' || $physId
                                }
                            ]
                        }
                    ],
                    'label': map {
                        'none': [$displayLabel]
                    },
                    'thumbnail': [
                        map {
                            'id': $baseUrl || '/full/' || $thumbnailWidth || ',/0/default.jpg',
                            'type': 'Image',
                            'format': 'image/jpeg',
                            'service': [
                                map {
                                    'id': $baseUrl,
                                    'type': 'ImageService' || $info?version,
                                    'profile': $info?profile
                                }
                            ],
                            'height': $thumbnailDimension?height,
                            'width': $thumbnailDimension?width
                        }
                    ]
                }
                ,
                if (string-length(normalize-space($fulltextUrl)) > 0)
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
                    map {}
                ))
                " />
    </xsl:function>

    <!--
        Funktion: ddblabs:transform-div
        Beschreibung:
          Rekursive Umwandlung eines mets:div-Baums in ein IIIF Range-Objekt.
          Verlinkte PHYS-IDs (structLink smLink/@xlink:from→@xlink:to) werden
          als Canvas-Referenzen angehängt.
    
        Parameter:
          - $div  (element(mets:div)): aktuelles Struktur-Div
          - $root (document-node()): Wurzel zur Auflösung aller Links
    
        Rückgabe:
          map(*) – IIIF Range mit id, type='Range', label und items (Ranges & Canvases)
    -->
    <xsl:function as="map(*)" name="ddblabs:transform-div">
        <xsl:param as="element(mets:div)" name="div" />

        <!--
          1) ID und Label aus DIV
          2) Alle Ziele aus structLink per Key lookup
          3) Alle Kind-Divs
        -->
        <xsl:variable name="id" select="string($div/@ID)" />
        <xsl:variable name="label" select="normalize-space($div/@LABEL)" />
        <xsl:variable name="orderLabel" select="normalize-space($div/@ORDERLABEL)" />
        <xsl:variable name="displayLabel" select="
                if ($label)
                then
                    concat(
                    $label,
                    if ($orderLabel)
                    then
                        concat(' (', $orderLabel, ')')
                    else
                        ()
                    )
                else
                    ($orderLabel, $id)[1]
                " />


        <xsl:variable name="targets" select="
                for $link in key('linkByFrom', $id, $root)
                return
                    string($link/@xlink:to)
                " />

        <xsl:variable name="childDivs" select="$div/mets:div" />

        <!--
          Items zusammenstellen:
          - zuerst transform-div auf alle Kind-Divs
          - danach Canvas-Maps für jeden target
          Bei keiner Kind-Div und keinem target, wird eine self-Range als Fallback angehängt.
        -->
        <xsl:variable as="array(*)" name="items">
            <xsl:sequence select="
                    array {
                        for $child in $childDivs
                        return
                            ddblabs:transform-div($child),
                        for $t in $targets
                        return
                            map {
                                'id': $itemUrl || '/canvas/' || $t,
                                'type': 'Canvas'
                            }
                    }" />
        </xsl:variable>

        <xsl:variable name="allItems" select="
                if (exists($items))
                then
                    $items
                else
                    array {
                        map {
                            'id': $itemUrl || '/range/' || $id,
                            'type': 'Range'
                        }
                    }
                " />

        <!-- Ergebnis-Map -->
        <xsl:sequence select="
                map {
                    'id': $itemUrl || '/range/' || $id,
                    'type': 'Range',
                    'label': map {'none': [$displayLabel]},
                    'items': $allItems
                }" />
    </xsl:function>

    <xsl:template match="/">
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
        <xsl:variable name="mods" select="/mets:mets/mets:dmdSec[1]/mets:mdWrap/mets:xmlData/mods:mods" />

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
        <xsl:variable name="labelNodes" select="$mods/mods:relatedItem/mods:titleInfo/mods:title" />
        <xsl:if test="$labelNodes">
            <xsl:map-entry key="'label'" select="
                    map {
                        'de': array {$labelNodes/text()}
                    }" />
        </xsl:if>
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
        <xsl:variable name="rightsNodes" select="$mods/mods:recordInfo/mods:recordInfoNote[@type = 'license']" />
        <xsl:if test="$rightsNodes">
            <xsl:map-entry key="'rights'" select="string($rightsNodes)" />
        </xsl:if>

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
        <xsl:variable as="xs:string" name="publisher">
            <xsl:sequence select="
                    ddblabs:generate-link(
                    if (exists($mods/mods:originInfo[@eventType = 'digitization']))
                    then
                        string($mods/mods:originInfo[@eventType = 'digitization']/mods:publisher[1])
                    else
                        string($mods/mods:originInfo[not(@eventType)][1]/mods:publisher[1]),
                    
                    $mods/mods:identifier[@type = 'purl'][1], true())
                    " />
        </xsl:variable>
        <xsl:if test="string-length($publisher) &gt; 0">
            <xsl:map-entry key="'requiredStatement'" select="
                    map {
                        'label': map {
                            'en': array {'Attribution'},
                            'de': array {'Zuschreibung'}
                        },
                        'value': map {
                            'none': array {
                                $publisher
                            }
                        }
                    }" />
        </xsl:if>
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
                "height": 1200,
                "width": 1600
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
                                        'width': 1600,
                                        'height': 1200,
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
                            map {},
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
                            map {}
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
                    for $div in /mets:mets/mets:structMap[@TYPE = 'LOGICAL']/mets:div
                    return
                        ddblabs:transform-div($div)
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
                            'height': 1200,
                            'width': 1600
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
            <xsl:variable name="divs" select="$allPageDivs" />
            <xsl:map-entry key="'items'" select="
                    array {
                        for $i in 1 to count($divs)
                        return
                            ddblabs:build-canvas($divs[$i], $i)
                    }
                    " />
        </xsl:map>
    </xsl:template>

    <xsl:template match="/" mode="iiif">
        <xsl:variable name="firstImageUrl" select="ddblabs:iiif-base-url(string(/mets:mets/mets:fileSec/mets:fileGrp[@USE = $preferredFileGrp]/mets:file[1]/mets:FLocat/@xlink:href))" />
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

            <!-- Bilddimensionen aus info.json -->
            <xsl:variable name="info" select="ddblabs:get-info($thumb || '/info.json')" />

            <!-- Thumbnail-Größe berechnen -->
            <xsl:variable name="thumbnailDimension" select="ddblabs:imageScale($info?width, $info?height, $thumbnailWidth, 0)" />

            <!-- IIIF-URL Suffix -->
            <xsl:variable name="urlSuffix" select="
                    if ($info?version = '3')
                    then
                        '/full/max/0/default.jpg'
                    else
                        '/full/full/0/default.jpg'" />

            <xsl:map-entry key="'thumbnail'" select="
                    array {
                        map {
                            'id': $thumb || '/full/' || $thumbnailWidth || ',/0/default.jpg',
                            'type': 'Image',
                            'format': 'image/jpeg',
                            'service': array {
                                map {
                                    'id': $thumb,
                                    'type': 'ImageService' || $info?version,
                                    'profile': $info?profile
                                }
                            },
                            'height': $thumbnailDimension?height,
                            'width': $thumbnailDimension?width
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
            <xsl:variable name="divs" select="$allPageDivs" />
            <xsl:map-entry key="'items'" select="
                    array {
                        for $i in 1 to count($divs)
                        return
                            ddblabs:build-iiif-canvas($divs[$i], $i)
                    }
                    " />
        </xsl:map>
    </xsl:template>

</xsl:stylesheet>
