<?xml version="1.0" encoding="UTF-8"?>
<!--
SPDX-FileCopyrightText: 2021 Michael Webster
SPDX-FileCopyrightText: 2021 Western Digital Corporation or its affiliates

SPDX-License-Identifier: GPL-3.0-or-later
-->
<xsl:stylesheet  version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" />
<xsl:output doctype-public="-//OASIS/DTD DocBook XML V4.5//EN" />
<xsl:output doctype-system="http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" />

<!-- Identity template -->
<xsl:template match="node()|@*">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
</xsl:template>

<!-- Add copyright notice -->
<xsl:template match="articleinfo/title">
    <xsl:copy-of select="." />
    <copyright>
        <year>2021</year>
        <holder>Michael Webster</holder>
        <holder>Western Digital Corporation or its affiliates</holder>
    </copyright>
</xsl:template>

<!-- Add PI for programlisting followed by a "Shrink-it:" paragraph -->
<!-- 
    I had to do this because Pandoc won't let me add any attributes to the code
    block directly.  I guess because I'm outputing Docbook and Pandoc doesn't
    seem to support putting attributes on anything other than HTML.
-->
<xsl:template match="programlisting">
    <xsl:choose>
        <xsl:when test="contains(following-sibling::para/text(),'Shrink-it:')">
            <programlisting>
                <xsl:apply-templates select="@*"/>
                <xsl:processing-instruction name="db-font-size">
                <xsl:value-of select="substring(normalize-space(following-sibling::para/text()),12)"/>
                </xsl:processing-instruction>
                <xsl:apply-templates select="node()"/>
            </programlisting>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>
                <xsl:apply-templates select="@*|node()" />
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- Delete the Shrink-it paragraph -->
<xsl:template match="para[contains(text(),'Shrink-it:')]"/>

<!-- Set background color of table footer -->
<xsl:template match="tfoot/row">
    <row>
        <xsl:processing-instruction name="dbfo">bgcolor="#EEEEEE"</xsl:processing-instruction>
        <xsl:apply-templates select="@*|node()" />
    </row>
</xsl:template>

</xsl:stylesheet>