<?xml version='1.0'?>
<!--
SPDX-FileCopyrightText: 2021 Michael Webster
SPDX-FileCopyrightText: 2021 Western Digital Corporation or its affiliates

SPDX-License-Identifier: GPL-3.0-or-later
-->
<xsl:stylesheet  version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
>

<xsl:import href="http://docbook.sourceforge.net/release/xsl/current/fo/docbook.xsl"/>

<xsl:param name="ulink.show">0</xsl:param>

<xsl:attribute-set name="section.level1.properties">
  <xsl:attribute name="break-before">page</xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="xref.properties">
  <xsl:attribute name="color">
    <xsl:choose>
      <xsl:when test="self::ulink">blue</xsl:when>
      <xsl:otherwise>inherit</xsl:otherwise>
    </xsl:choose>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:attribute-set name="monospace.verbatim.properties">
  <xsl:attribute name="font-size">
    <xsl:choose>
      <xsl:when test="processing-instruction('db-font-size')"><xsl:value-of
           select="processing-instruction('db-font-size')"/></xsl:when>
      <xsl:otherwise>inherit</xsl:otherwise>
    </xsl:choose>
  </xsl:attribute>
</xsl:attribute-set>

<xsl:param name="default.table.frame">all</xsl:param>
<xsl:param name="default.table.rules">groups</xsl:param>

<xsl:attribute-set name="table.table.properties">
  <xsl:attribute name="border-after-width.conditionality">retain</xsl:attribute>
  <xsl:attribute name="border-before-width.conditionality">retain</xsl:attribute>
  <xsl:attribute name="border-collapse">collapse</xsl:attribute>
</xsl:attribute-set>

</xsl:stylesheet>
