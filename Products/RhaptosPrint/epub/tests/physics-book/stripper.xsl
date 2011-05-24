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

<xsl:import href="../../xsl/ident.xsl"/>

<xsl:template match="db:preface">
<xsl:apply-templates/>
</xsl:template>

<xsl:template match="db:prefaceinfo"/>

<xsl:template match="db:book/db:preface/db:section[position()=1]">
  <db:chapter>
    <xsl:apply-templates select="@*|node()"/>
  </db:chapter>
</xsl:template>


<!-- TODO: Hack to get a separate end-of-book section for solutions. move into normal pipeline -->
<xsl:template match="db:book">
  <xsl:copy>
    <xsl:apply-templates select="@*|node()"/>
    <ext:cnx-solutions-placeholder>
      <db:title>Answers</db:title>
    </ext:cnx-solutions-placeholder>
    <!-- Auto-generate an index -->
    <db:index/>
  </xsl:copy>
</xsl:template>


</xsl:stylesheet>

