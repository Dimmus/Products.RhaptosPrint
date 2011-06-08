<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:d="http://docbook.org/ns/docbook"
  xmlns:fo="http://www.w3.org/1999/XSL/Format"
  xmlns:ext="http://cnx.org/ns/docbook+"
  version="1.0">

<xsl:import href="modern-text.xsl"/>

<!-- ============================================== -->
<!-- Customize docbook params for this style        -->
<!-- ============================================== -->

<xsl:param name="alignment">start</xsl:param>

<xsl:param name="column.count.titlepage" select="1"/>
<xsl:param name="column.count.lot" select="1"/>
<xsl:param name="column.count.front" select="2"/>
<xsl:param name="column.count.body" select="2"/>
<xsl:param name="column.count.back" select="2"/>
<xsl:param name="column.count.index" select="2"/>

<!-- Let @span='all' percolate through -->
<xsl:template match="@class[.='span-all']">
  <xsl:attribute name="span">all</xsl:attribute>
</xsl:template>


<!-- ============================================== -->
<!-- Custom page layouts for modern-textbook        -->
<!-- ============================================== -->

<!-- Generate custom page layouts for:
     - Chapter introduction
     - 2-column end-of-chapter problems
-->
<xsl:param name="cnx.pagemaster.body">cnx-body</xsl:param>
<xsl:param name="cnx.pagemaster.problems">cnx-problems-2column</xsl:param>
<xsl:template name="user.pagemasters">
    <!-- title pages -->
    <fo:simple-page-master master-name="{$cnx.pagemaster.problems}"
                           page-width="{$page.width}"
                           page-height="{$page.height}"
                           margin-top="{$page.margin.top}"
                           margin-bottom="{$page.margin.bottom}">
      <xsl:attribute name="margin-{$direction.align.start}">
        <xsl:value-of select="$cnx.margin.problems"/>
      </xsl:attribute>
      <xsl:attribute name="margin-{$direction.align.end}">
        <xsl:value-of select="$cnx.margin.problems"/>
      </xsl:attribute>
      <fo:region-body margin-bottom="{$body.margin.bottom}"
                      margin-top="{$body.margin.top}"
                      column-gap="{$column.gap.titlepage}"
                      column-count="2">
      </fo:region-body>
      <fo:region-before region-name="xsl-region-before-first"
                        extent="{$region.before.extent}"
                        display-align="before"/>
      <fo:region-after region-name="xsl-region-after-first"
                       extent="{$region.after.extent}"
                        display-align="after"/>
    </fo:simple-page-master>
    
    <!-- setup for body pages -->
    <fo:page-sequence-master master-name="{$cnx.pagemaster.body}">
      <fo:repeatable-page-master-alternatives>
        <fo:conditional-page-master-reference 
                master-reference="{$cnx.pagemaster.body}-odd"/>
      </fo:repeatable-page-master-alternatives>
    </fo:page-sequence-master>

    <fo:simple-page-master master-name="{$cnx.pagemaster.body}-odd"
                           page-width="{$page.width}"
                           page-height="{$page.height}"
                           margin-top="{$page.margin.top}"
                           margin-bottom="{$page.margin.bottom}">
      <xsl:attribute name="margin-{$direction.align.start}">
        <xsl:value-of select="$cnx.margin.problems"/>
      </xsl:attribute>
      <xsl:attribute name="margin-{$direction.align.end}">
        <xsl:value-of select="$cnx.margin.problems"/>
      </xsl:attribute>
      <fo:region-body margin-bottom="{$body.margin.bottom}"
                      margin-top="{$body.margin.top}"
                      column-gap="{$column.gap.titlepage}"
                      column-count="2">
      </fo:region-body>
      <fo:region-before region-name="xsl-region-before-first"
                        extent="{$region.before.extent}"
                        display-align="before"/>
      <fo:region-after region-name="xsl-region-after-first"
                       extent="{$region.after.extent}"
                        display-align="after"/>
    </fo:simple-page-master>


    <fo:simple-page-master master-name="{$cnx.pagemaster.body}-first"
                           page-width="{$page.width}"
                           page-height="{$page.height}"
                           margin-top="{$page.margin.top}"
                           margin-bottom="{$page.margin.bottom}">
      <xsl:attribute name="margin-{$direction.align.start}">
        <xsl:value-of select="$page.margin.outer"/>
      </xsl:attribute>
      <xsl:attribute name="margin-{$direction.align.end}">
        <xsl:value-of select="$page.margin.outer"/>
      </xsl:attribute>
      <xsl:if test="$axf.extensions != 0">
        <xsl:call-template name="axf-page-master-properties">
          <xsl:with-param name="page.master">body-odd</xsl:with-param>
        </xsl:call-template>
      </xsl:if>
      <fo:region-body margin-bottom="{$body.margin.bottom}"
                      margin-top="{$body.margin.top}"
                      column-gap="{$column.gap.body}"
                      column-count="1">
      </fo:region-body>
      <fo:region-before region-name="xsl-region-before-odd"
                        extent="{$region.before.extent}"
                        display-align="before"/>
      <fo:region-after region-name="xsl-region-after-odd"
                       extent="{$region.after.extent}"
                       display-align="after"/>
    </fo:simple-page-master>

</xsl:template>

</xsl:stylesheet>
