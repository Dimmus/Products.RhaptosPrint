<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:md="http://cnx.rice.edu/mdml/0.4" xmlns:bib="http://bibtexml.sf.net/"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:svg="http://www.w3.org/2000/svg"
  xmlns:pmml2svg="https://sourceforge.net/projects/pmml2svg/"
  version="1.0">

<xsl:import href="param.xsl"/>
<xsl:import href="debug.xsl"/>
<xsl:import href="ident.xsl"/>

<xsl:output indent="yes" method="xml"/>

<xsl:template mode="copy" match="@*|node()">
    <xsl:copy>
        <xsl:apply-templates mode="copy" select="@*|node()"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="db:informalequation">
	<db:equation>
		<xsl:apply-templates select="@*"/>
		<db:title/>
		<xsl:apply-templates select="node()"/>
	</db:equation>
</xsl:template>

<xsl:template match="db:informalexample">
	<db:example>
		<xsl:apply-templates select="@*"/>
		<db:title/>
		<xsl:apply-templates select="node()"/>
	</db:example>
</xsl:template>

<xsl:template match="db:informalfigure">
	<db:figure>
		<xsl:apply-templates select="@*"/>
		<db:title/>
		<xsl:apply-templates select="node()"/>
	</db:figure>
</xsl:template>


<xsl:template match="db:inlinemediaobject[.//mml:math]">
	<xsl:call-template name="cnx.log"><xsl:with-param name="msg">BUG: Inline MathML Not converted</xsl:with-param></xsl:call-template>
	<xsl:text>[ERROR: MathML not converted]</xsl:text>
</xsl:template>

<xsl:template match="db:mediaobject[.//mml:math]">
	<xsl:call-template name="cnx.log"><xsl:with-param name="msg">BUG: MathML Not converted</xsl:with-param></xsl:call-template>
	<db:para>[ERROR: MathML not converted]</db:para>
</xsl:template>


<!-- Discard unmatched xinclude files -->
<!-- col10363 has, for every eps file, a svg file and FOP doesn't support eps. -->
<xsl:template match="*[db:imageobject/db:imagedata/xi:include]">
	<xsl:call-template name="cnx.log"><xsl:with-param name="msg">ERROR: xincluded file not found. <xsl:value-of select="db:imageobject/db:imagedata/xi:include/@href"/></xsl:with-param></xsl:call-template> 
</xsl:template>
<!-- But if there is a PNG fallback, let it through -->
<xsl:template match="*[db:imageobject/db:imagedata/xi:include and db:imageobject/db:imagedata[@fileref]]">
	<xsl:call-template name="cnx.log"><xsl:with-param name="msg">WARNING: Using non-svg alternate for eps file. <xsl:value-of select="db:imageobject/db:imagedata/@fileref"/></xsl:with-param></xsl:call-template> 
	<xsl:copy>
		<xsl:apply-templates select="@*"/>
		<db:imageobject>
			<db:imagedata>
				<xsl:apply-templates select="db:imageobject/db:imagedata[@fileref]/@*"/>
				<xsl:apply-templates select="db:imageobject/db:imagedata[@fileref]/node()"/>
			</db:imagedata>
		</db:imageobject>
	</xsl:copy>
</xsl:template>

<!-- FOP needs the pmml2svg:baseline-shift element to move the math, but all others don't -->
<xsl:template match="svg:metadata[pmml2svg:baseline-shift]">
	<xsl:call-template name="ident"/>
</xsl:template>


</xsl:stylesheet>
