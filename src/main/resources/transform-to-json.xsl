<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform expand-text="yes" version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output encoding="UTF-8" method="text" />
    <xsl:template match="/">
        <xsl:value-of select="xml-to-json(.)" />
        <!-- <xsl:value-of select="xml-to-json(., map { 'indent' : true() })"/> -->
    </xsl:template>
</xsl:transform>
