<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:pmml2svg="https://sourceforge.net/projects/pmml2svg/"
  xmlns:c="http://cnx.rice.edu/cnxml"
  xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
  xmlns:ext="http://cnx.org/ns/docbook+"
  version="1.0">

<!-- This file converts dbk+ extension elements (like exercise problem and solution)
	 using the Docbook templates.
	* Customizes title generation
	* Numbers exercises
	* Labels exercises (and links to them)
 -->



<!-- EXERCISE templates -->

<!-- Generate custom HTML for an ext:problem and ext:solution.
	Taken from docbook-xsl/xhtml-1_1/formal.xsl: <xsl:template match="example">
 -->
<xsl:template match="ext:exercise|ext:problem|ext:solution">

  <xsl:variable name="param.placement" select="substring-after(normalize-space($formal.title.placement), concat(local-name(.), ' '))"/>

  <xsl:variable name="placement">
    <xsl:choose>
      <xsl:when test="contains($param.placement, ' ')">
        <xsl:value-of select="substring-before($param.placement, ' ')"/>
      </xsl:when>
      <xsl:when test="$param.placement = ''">before</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$param.placement"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="formal.object">
    <xsl:with-param name="placement" select="$placement"/>
  </xsl:call-template>

</xsl:template>

<!-- Can't use docbook-xsl/common/gentext.xsl because labels and titles can contain XML (makes things icky) -->
<xsl:template match="ext:*" mode="object.title.markup">
	<xsl:apply-templates select="." mode="cnx.template"/>
</xsl:template>

<!-- Link to the exercise and to the solution. HACK: We can do this because solutions are within a module (html file) -->
<xsl:template match="ext:exercise" mode="object.title.markup">
	<xsl:apply-templates select="." mode="cnx.template"/>
	<xsl:variable name="id" select="@id"/>
        <xsl:for-each select="//ext:solution[@exercise-id=$id]">
                <xsl:text> </xsl:text>
                <!-- TODO: gentext for "(" -->
                <xsl:text>(</xsl:text>
                <xsl:call-template name="simple.xlink">
                        <xsl:with-param name="linkend" select="@id"/>
                        <xsl:with-param name="content">
                                <!-- TODO: gentext for "Go to" -->
                                <xsl:text>Go to</xsl:text>
                                <xsl:text> </xsl:text>
                                <xsl:choose>
                                        <xsl:when test="ext:label">
                                                <xsl:apply-templates select="ext:label" mode="cnx.label" />
                                        </xsl:when>
                                        <xsl:otherwise>
                                                <!-- TODO: gentext for "Solution" -->
                                                <xsl:text>Solution</xsl:text>
                                        </xsl:otherwise>
                                </xsl:choose>
                                <xsl:if test="count(../ext:solution[@exercise-id=$id]) > 1">
                                        <xsl:number count="ext:solution[@exercise-id=$id]" format=" A"/>
                                </xsl:if>
                        </xsl:with-param>
                </xsl:call-template>
                <!-- TODO: gentext for ")" -->
                <xsl:text>)</xsl:text>
        </xsl:for-each>
</xsl:template>

<xsl:template match="ext:solution" mode="object.title.markup">
	<xsl:apply-templates select="." mode="cnx.template"/>
	<xsl:variable name="exerciseId" select="@exercise-id"/>
	<xsl:if test="$exerciseId!=''">
		<xsl:text> </xsl:text>
                <!-- TODO: gentext for "(" -->
		<xsl:text>(</xsl:text>
		  <xsl:call-template name="simple.xlink">
		    <xsl:with-param name="linkend" select="$exerciseId"/>
		    <xsl:with-param name="content">
                        <!-- TODO: gentext for "Return to" -->
		    	<xsl:text>Return to</xsl:text>
                        <xsl:text> </xsl:text>
                        <xsl:choose>
                            <xsl:when test="//ext:exercise[@id=$exerciseId]/ext:label">
                                <xsl:apply-templates select="//ext:exercise[@id=$exerciseId]/ext:label" mode="cnx.label" />
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- TODO: gentext for "Exercise" -->
                                <xsl:text>Exercise</xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
		    </xsl:with-param>
		  </xsl:call-template>
                <!-- TODO: gentext for ")" -->
		<xsl:text>)</xsl:text>
	</xsl:if>
</xsl:template>

<xsl:template match="ext:exercise|ext:problem|ext:solution" mode="insert.label.markup">
	<xsl:param name="label" select="ext:label"/>
	<xsl:if test="$label!=''">
		<xsl:apply-templates select="$label" mode="cnx.label"/>
		<xsl:text> </xsl:text>
	</xsl:if>
	<xsl:apply-templates select="." mode="number"/>
</xsl:template>

<xsl:template match="ext:*[not(title)]" mode="title.markup"/>
<xsl:template match="ext:*/title"/>
<xsl:template match="ext:exercise|ext:problem|ext:solution" mode="label.markup"/>

<xsl:template match="ext:exercise" mode="cnx.template">
	<xsl:choose>
		<xsl:when test="ext:label">
			<xsl:apply-templates select="ext:label" mode="cnx.label"/>
		</xsl:when>
		<xsl:otherwise>
                        <!-- TODO: gentext for "Exercise" -->
			<xsl:text>Exercise</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="." mode="number"/>
	<xsl:if test="title">
		<xsl:text> : </xsl:text>
		<xsl:apply-templates select="." mode="title.markup"/>
	</xsl:if>
</xsl:template>

<xsl:template match="ext:problem[not(ext:label)]" mode="cnx.template">
        <xsl:apply-templates select="title"/>
</xsl:template>

<xsl:template match="ext:solution" mode="cnx.template">
        <xsl:variable name="exerciseId" select="@exercise-id"/>
        <xsl:choose>
                <xsl:when test="ext:label">
                	<xsl:apply-templates select="ext:label" mode="cnx.label"/>
                </xsl:when>
                <xsl:otherwise>
                        <!-- TODO: gentext for "Solution" -->
                        <xsl:text>Solution</xsl:text>
                </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="count(../ext:solution[@exercise-id=$exerciseId]) > 1">
                <xsl:number count="ext:solution[@exercise-id=$exerciseId]" format=" A"/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <!-- TODO: gentext for "to" -->
        <xsl:text>to</xsl:text>
        <xsl:text> </xsl:text>
        <xsl:choose>
                <xsl:when test="//ext:exercise[@id=$exerciseId]/ext:label">
                        <xsl:apply-templates select="//ext:exercise[@id=$exerciseId]/ext:label" mode="cnx.label" />
                </xsl:when>
                <xsl:otherwise>
                        <!-- TODO: gentext for "Exercise" -->
                        <xsl:text>Exercise</xsl:text>
                </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="number"/>
</xsl:template>

<xsl:template match="ext:*[ext:label]" mode="cnx.template" priority="0">
	<xsl:apply-templates select="ext:label" mode="cnx.label"/>
	<xsl:if test="title">
		<xsl:text> : </xsl:text>
		<xsl:apply-templates select="." mode="title.markup"/>
	</xsl:if>
</xsl:template>

<xsl:template match="ext:label" mode="cnx.label">
	<xsl:apply-templates select="node()"/>
</xsl:template>

<xsl:template match="ext:label"/>



<!-- NUMBERING templates -->

<!-- By default, nothing is numbered. -->
<xsl:template match="ext:*" mode="number"/>

<xsl:template match="ext:exercise" mode="number">
	<xsl:if test="ancestor::chapter|ancestor::appendix">
		<xsl:apply-templates select="ancestor::*[@ext:element='module']" mode="cnxnumber"/>
		<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	</xsl:if>
	<xsl:number format="1" level="any" from="chapter" count="ext:exercise[not(ancestor::*[ext:element='example'])]"/>
</xsl:template>

<!-- Either a module is a chapter, or a section in a chapter -->
<xsl:template match="preface|chapter|appendix" mode="cnxnumber">
	<xsl:apply-templates select="." mode="label.markup"/>
</xsl:template>

<xsl:template match="*[@ext:element='module']" mode="cnxnumber">
	<xsl:if test="ancestor::chapter|ancestor::appendix">
		<xsl:apply-templates select="ancestor::preface|ancestor::chapter|ancestor::appendix" mode="cnxnumber"/>
		<xsl:apply-templates select="." mode="intralabel.punctuation"/>
	</xsl:if>
	<xsl:number from="preface|chapter|appendix" count="*[@ext:element='module']"/>
</xsl:template>

<xsl:template match="*" mode="cnxnumber">
	<xsl:call-template name="cnx.log"><xsl:with-param name="msg">BUG: tried to get a cnxnumber for something other than a preface|chapter|appendix|*[@ext:element='module']</xsl:with-param></xsl:call-template>
</xsl:template>

<xsl:template match="ext:solution" mode="number">
	<xsl:variable name="exerciseId" select="@exercise-id"/>
	<xsl:apply-templates select="//*[@id=$exerciseId]" mode="number"/>
</xsl:template>



<!-- XREF templates -->

<xsl:template match="ext:*" mode="xref-to">
	<xsl:apply-templates select="." mode="object.xref.markup"/>
</xsl:template>

<xsl:template match="ext:*" mode="object.xref.markup">
  <xsl:param name="purpose"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="referrer"/>
  <xsl:param name="verbose" select="1"/>
	<!-- TODO: Reimplement using gentext defaults -->
	<xsl:apply-templates select="." mode="cnx.template"/>
</xsl:template>

</xsl:stylesheet>