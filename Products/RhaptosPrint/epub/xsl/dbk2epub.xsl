<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:pmml2svg="https://sourceforge.net/projects/pmml2svg/"
  xmlns:c="http://cnx.rice.edu/cnxml"
  xmlns:ncx="http://www.daisy.org/z3986/2005/ncx/"
  xmlns:ext="http://cnx.org/ns/docbook+"
  version="1.0">

<!-- This file converts dbk files to chunked html which is used in EPUB generation.
	* Stores customizations and docbook settings specific to Connexions
	* Shifts images that were converted from MathML so they line up with text nicely
	* Puts equation numbers on the RHS of an equation
	* Disables equation and figure numbering inside things like examples and glossaries
	* Adds @class attributes to elements for custom styling (like c:rule, c:figure)
 -->

<xsl:import href="debug.xsl"/>
<xsl:import href="../docbook-xsl/epub/docbook.xsl"/>
<xsl:import href="param.xsl"/>
<xsl:include href="dbkplus.xsl"/>
<xsl:include href="table2epub.xsl"/>

<!-- Number the sections 1 level deep. See http://docbook.sourceforge.net/release/xsl/current/doc/html/ -->
<xsl:param name="section.autolabel" select="1"></xsl:param>
<xsl:param name="section.autolabel.max.depth">1</xsl:param>
<xsl:param name="chunk.section.depth" select="0"></xsl:param>
<xsl:param name="chunk.first.sections" select="0"></xsl:param>

<xsl:param name="section.label.includes.component.label">1</xsl:param>
<xsl:param name="xref.with.number.and.title">0</xsl:param>
<xsl:param name="toc.section.depth">0</xsl:param>

<xsl:output indent="yes" method="xml"/>

<!-- Output the PNG with the baseline info -->
<xsl:template match="@pmml2svg:baseline-shift">
	<xsl:attribute name="style">
	    <!-- Ignore width and height information for now
		<xsl:text>widt</xsl:text>
		<xsl:value-of select="@width"/>
		<xsl:text>; height:</xsl:text>
		<xsl:value-of select="@depth"/>
		<xsl:text>;</xsl:text>
		-->
	  	<xsl:text>vertical-align:-</xsl:text>
	  	<xsl:value-of select="." />
	  	<xsl:text>pt;</xsl:text>
  	</xsl:attribute>
</xsl:template>

<!-- Ignore the SVG element and use the @fileref (SVG-to-PNG conversion) -->
<xsl:template match="*['imagedata'=local-name() and @fileref]" xmlns:svg="http://www.w3.org/2000/svg">
	<img src="{@fileref}">
		<xsl:apply-templates select="@pmml2svg:baseline-shift"/>
		<!-- Ignore the SVG child -->
	</img>
<!--
  <object id="{$id}" type="image/svg+xml" data="{$chunkfn}" width="{@width}" height="{@height}">
 	<xsl:if test="svg:metadata/pmml2svg:baseline-shift">
  	  <xsl:attribute name="style">position:relative; top:<xsl:value-of
		select="svg:metadata/pmml2svg:baseline-shift" />px;</xsl:attribute>
  	</xsl:if>
	<img src="{@fileref}" width="{@width}" height="{@height}"/>
  </object>
--></xsl:template>

<xsl:template match="db:imagedata[@fileref and svg:svg]" xmlns:svg="http://www.w3.org/2000/svg">
	<xsl:choose>
		<xsl:when test="$cnx.svg.compat = 'object'">
		  <object type="image/png" data="{@fileref}" width="{@width}" height="{@height}">
			<xsl:apply-templates select="@pmml2svg:baseline-shift"/>
			<!-- Insert the SVG inline -->
			<xsl:apply-templates select="node()"/>
		  </object>
		</xsl:when>
		<xsl:otherwise>
			<img src="{@fileref}">
				<xsl:apply-templates select="@pmml2svg:baseline-shift"/>
			</img>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>



<!-- Put the equation number on the RHS -->
<xsl:template match="db:equation">
  <div class="equation">
    <xsl:attribute name="id">
      <xsl:call-template name="object.id"/>
    </xsl:attribute>
	<xsl:apply-templates/>
	<span class="label">
	  <xsl:text>(</xsl:text>
	  <xsl:apply-templates select="." mode="label.markup"/>
      <xsl:text>)</xsl:text>
    </span>
  </div>
</xsl:template>


<!-- Don't number examples inside exercises. Original code taken from docbook-xsl/common/labels.xsl -->
<xsl:template match="db:example[ancestor::db:glossentry
            or ancestor::*[@ext:element='rule']
            ]" mode="label.markup">
</xsl:template>
<xsl:template match="db:example[ancestor::db:glossentry
            or ancestor::*[@ext:element='rule']
            ]" mode="intralabel.punctuation"/>
<xsl:template match="figure|table|example" mode="label.markup">
  <xsl:variable name="pchap"
                select="(ancestor::db:chapter
                        |ancestor::db:appendix
                        |ancestor::db:article[ancestor::db:book])[last()]"/>
  <xsl:variable name="name" select="name()"/>
  
  <xsl:variable name="prefix">
    <xsl:if test="count($pchap) &gt; 0">
      <xsl:apply-templates select="$pchap" mode="label.markup"/>
    </xsl:if>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="@label">
      <xsl:value-of select="@label"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$prefix != ''">
            <xsl:apply-templates select="$pchap" mode="label.markup"/>
            <xsl:apply-templates select="$pchap" mode="intralabel.punctuation"/>
          <xsl:number format="1" from="db:chapter|db:appendix" count="*[$name=name() and not(
               ancestor::db:glossentry
               or ancestor::*[@ext:element='rule']
               
          )]" level="any"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:number format="1" from="db:book|db:article" level="any" count="*[$name=name() and not(
               ancestor::db:glossentry
               or ancestor::*[@ext:element='rule']
               
          )]"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Override of docbook-xsl/xhtml-1_1/html.xsl -->
<xsl:template match="*[@ext:element|@class]" mode="class.value">
  <xsl:param name="class" select="local-name(.)"/>
  <xsl:variable name="cls">
  	<xsl:value-of select="$class"/>
  	<xsl:if test="@ext:element">
  		<xsl:text> </xsl:text>
  		<xsl:value-of select="@ext:element"/>
  	</xsl:if>
  	<xsl:if test="@class">
  		<xsl:text> </xsl:text>
  		<xsl:value-of select="@class"/>
  	</xsl:if>
  </xsl:variable>
  <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Adding to @class: "<xsl:value-of select="$cls"/>"</xsl:with-param></xsl:call-template>
  <!-- permit customization of class value only -->
  <!-- Use element name by default -->
  <xsl:value-of select="$cls"/>
</xsl:template>

<!-- Override of docbook-xsl/xhtml-1_1/xref.xsl -->
<xsl:template match="*[@XrefLabel]" mode="xref-to">
	<xsl:value-of select="@XrefLabel"/>
</xsl:template>

<xsl:template match="db:inlineequation" mode="xref-to">
	<xsl:text>Equation</xsl:text>
</xsl:template>

<xsl:template match="db:caption" mode="xref-to">
	<xsl:apply-templates select="."/>
</xsl:template>

<!-- Subfigures are converted to images inside a figure with an anchor.
	With this code, any xref to a subfigure contains the text of the figure.
	I just added "ancestor::figure" when searching for the context.
 -->
<xsl:template match="db:anchor" mode="xref-to">
  <xsl:param name="referrer"/>
  <xsl:param name="xrefstyle"/>
  <xsl:param name="verbose" select="1"/>

  <xsl:variable name="context" select="(ancestor::db:figure| ancestor::db:simplesect                                        |ancestor::section                                        |ancestor::sect1                                        |ancestor::sect2                                        |ancestor::sect3                                        |ancestor::sect4                                        |ancestor::sect5                                        |ancestor::refsection                                        |ancestor::refsect1                                        |ancestor::refsect2                                        |ancestor::refsect3                                        |ancestor::chapter                                        |ancestor::appendix                                        |ancestor::preface                                        |ancestor::partintro                                        |ancestor::dedication                                        |ancestor::acknowledgements                                        |ancestor::colophon                                        |ancestor::bibliography                                        |ancestor::index                                        |ancestor::glossary                                        |ancestor::glossentry                                        |ancestor::listitem                                        |ancestor::varlistentry)[last()]"/>

  <xsl:choose>
    <xsl:when test="$xrefstyle != ''">
      <xsl:apply-templates select="." mode="object.xref.markup">
        <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
        <xsl:with-param name="referrer" select="$referrer"/>
        <xsl:with-param name="verbose" select="$verbose"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="$context" mode="xref-to">
        <xsl:with-param name="purpose" select="'xref'"/>
        <xsl:with-param name="xrefstyle" select="$xrefstyle"/>
        <xsl:with-param name="referrer" select="$referrer"/>
        <xsl:with-param name="verbose" select="$verbose"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- Add a template for newlines.
     The cnxml2docbook adds a processing instruction named <?cnx.newline?>
     and is matched here
     see http://www.sagehill.net/docbookxsl/LineBreaks.html
-->
<xsl:template match="processing-instruction('cnx.newline')">
	<xsl:comment>cnx.newline</xsl:comment>
	<br/>
</xsl:template>
<xsl:template match="processing-instruction('cnx.newline.underline')">
	<xsl:comment>cnx.newline.underline</xsl:comment>
	<hr/>
</xsl:template>

<!-- Fix up TOC-generation for the ncx file.
	Overrides code in docbook-xsl/docbook.xsl using code from docbook-xsl/xhtml-1_1/autotoc.xsl
 -->
  <xsl:template match="db:book|
                       db:article|
                       db:part|
                       db:reference|
                       db:preface|
                       db:chapter|
                       db:bibliography|
                       db:appendix|
                       db:glossary|
                       db:section|
                       db:sect1|
                       db:sect2|
                       db:sect3|
                       db:sect4|
                       db:sect5|
                       db:refentry|
                       db:colophon|
                       db:bibliodiv[db:title]|
                       db:setindex|
                       db:index"
                mode="ncx">
    <xsl:variable name="depth" select="count(ancestor::*)"/>
    <xsl:variable name="title">
      <xsl:if test="$epub.autolabel != 0">
        <xsl:variable name="label.markup">
          <xsl:apply-templates select="." mode="label.markup" />
        </xsl:variable>
        <xsl:if test="normalize-space($label.markup)">
          <xsl:value-of
            select="concat($label.markup,$autotoc.label.separator)" />
        </xsl:if>
      </xsl:if>
      <xsl:apply-templates select="." mode="title.markup" />
    </xsl:variable>

    <xsl:variable name="href">
      <xsl:call-template name="href.target.with.base.dir">
        <xsl:with-param name="context" select="/" />
        <!-- Generate links relative to the location of root file/toc.xml file -->
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="id">
      <xsl:value-of select="generate-id(.)"/>
    </xsl:variable>
    <xsl:variable name="order">
      <xsl:value-of select="$depth +
                                  count(preceding::db:part|
                                  preceding::db:reference|
                                  preceding::db:book[parent::db:set]|
                                  preceding::db:preface|
                                  preceding::db:chapter|
                                  preceding::db:bibliography|
                                  preceding::db:appendix|
                                  preceding::db:article|
                                  preceding::db:glossary|
                                  preceding::db:section[not(parent::db:partintro)]|
                                  preceding::db:sect1[not(parent::db:partintro)]|
                                  preceding::db:sect2|
                                  preceding::db:sect3|
                                  preceding::db:sect4|
                                  preceding::db:sect5|
                                  preceding::refentry|
                                  preceding::db:colophon|
                                  preceding::db:bibliodiv[db:title]|
                                  preceding::db:index)"/>
    </xsl:variable>


  <xsl:variable name="depth2">
    <xsl:choose>
      <xsl:when test="local-name(.) = 'section'">
        <xsl:value-of select="count(ancestor::db:section) + 1"/>
      </xsl:when>
      <xsl:when test="local-name(.) = 'sect1'">1</xsl:when>
      <xsl:when test="local-name(.) = 'sect2'">2</xsl:when>
      <xsl:when test="local-name(.) = 'sect3'">3</xsl:when>
      <xsl:when test="local-name(.) = 'sect4'">4</xsl:when>
      <xsl:when test="local-name(.) = 'sect5'">5</xsl:when>
      <xsl:when test="local-name(.) = 'refsect1'">1</xsl:when>
      <xsl:when test="local-name(.) = 'refsect2'">2</xsl:when>
      <xsl:when test="local-name(.) = 'refsect3'">3</xsl:when>
      <xsl:when test="local-name(.) = 'simplesect'">
        <!-- sigh... -->
        <xsl:choose>
          <xsl:when test="local-name(..) = 'section'">
            <xsl:value-of select="count(ancestor::db:section)"/>
          </xsl:when>
          <xsl:when test="local-name(..) = 'sect1'">2</xsl:when>
          <xsl:when test="local-name(..) = 'sect2'">3</xsl:when>
          <xsl:when test="local-name(..) = 'sect3'">4</xsl:when>
          <xsl:when test="local-name(..) = 'sect4'">5</xsl:when>
          <xsl:when test="local-name(..) = 'sect5'">6</xsl:when>
          <xsl:when test="local-name(..) = 'refsect1'">2</xsl:when>
          <xsl:when test="local-name(..) = 'refsect2'">3</xsl:when>
          <xsl:when test="local-name(..) = 'refsect3'">4</xsl:when>
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

	<xsl:if test="not(local-name()='section' or local-name()='simplesect') or $toc.section.depth &gt; $depth2">

    <xsl:element name="ncx:navPoint">
      <xsl:attribute name="id">
        <xsl:value-of select="$id"/>
      </xsl:attribute>

      <xsl:attribute name="playOrder">
        <xsl:choose>
          <xsl:when test="/*[self::db:set]">
            <xsl:value-of select="$order"/>
          </xsl:when>
          <xsl:when test="$root.is.a.chunk != '0'">
            <xsl:value-of select="$order + 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$order - 0"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:element name="ncx:navLabel">
        <xsl:element name="ncx:text"><xsl:value-of select="normalize-space($title)"/> </xsl:element>
      </xsl:element>
      <xsl:element name="ncx:content">
        <xsl:attribute name="src">
          <xsl:value-of select="$href"/>
        </xsl:attribute>
      </xsl:element>
      <xsl:apply-templates select="db:book[parent::db:set]|db:part|db:reference|db:preface|db:chapter|db:bibliography|db:appendix|db:article|db:glossary|db:section|db:sect1|db:sect2|db:sect3|db:sect4|db:sect5|db:refentry|db:colophon|db:bibliodiv[db:title]|db:setindex|db:index" mode="ncx"/>
    </xsl:element>

	</xsl:if>

  </xsl:template>


<!-- Make the title page show up first in readers.
	Originally in docbook-xsl/epub/docbook.xsl
 -->
  <xsl:template name="opf.spine">

    <xsl:element namespace="http://www.idpf.org/2007/opf" name="spine">
      <xsl:attribute name="toc">
        <xsl:value-of select="$epub.ncx.toc.id"/>
      </xsl:attribute>
      
	  <!-- Make sure the title page is the 1st item in the spine -->
	  <xsl:element namespace="http://www.idpf.org/2007/opf" name="itemref">
	  	<xsl:attribute name="idref">
	  		<xsl:value-of select="generate-id(db:book)"/>
	  	</xsl:attribute>
	  </xsl:element>

      <xsl:if test="/*/*[db:cover or contains(name(.), 'info')]//db:mediaobject[@role='cover' or ancestor::db:cover]"> 
        <xsl:element namespace="http://www.idpf.org/2007/opf" name="itemref">
          <xsl:attribute name="idref">
            <xsl:value-of select="$epub.cover.id"/>
          </xsl:attribute>
          <xsl:attribute name="linear">
          <xsl:choose>
            <xsl:when test="$epub.cover.linear">
              <xsl:text>yes</xsl:text>
            </xsl:when>
            <xsl:otherwise>no</xsl:otherwise>
          </xsl:choose>
          </xsl:attribute>
        </xsl:element>
      </xsl:if>


      <xsl:if test="contains($toc.params, 'toc')">
        <xsl:element namespace="http://www.idpf.org/2007/opf" name="itemref">
          <xsl:attribute name="idref"> <xsl:value-of select="$epub.html.toc.id"/> </xsl:attribute>
          <xsl:attribute name="linear">yes</xsl:attribute>
        </xsl:element>
      </xsl:if>  

      <!-- TODO: be nice to have a idref="titlepage" here -->
      <xsl:choose>
        <xsl:when test="$root.is.a.chunk != '0'">
          <xsl:apply-templates select="/*" mode="opf.spine"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="/*/*" mode="opf.spine"/>
        </xsl:otherwise>
      </xsl:choose>
                                   
    </xsl:element>
  </xsl:template>


<!-- Customize the metadata generated for the epub.
	Originally from docbook-xsl/epub/docbook.xsl -->
<xsl:template mode="opf.metadata" match="db:authorgroup">
	<xsl:apply-templates mode="opf.metadata" select="node()"/>
</xsl:template>

<!-- Customize the title page.
	TODO: All of these can be made nicer using gentext and the %t replacements
 -->
<xsl:template name="book.titlepage">
	<h2>
		<xsl:value-of select="db:bookinfo/db:title/text()"/>
	</h2>
	<xsl:variable name="authors">
		<xsl:call-template name="person.name.list">
			<xsl:with-param name="person.list" select="db:bookinfo/db:authorgroup/db:author"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="editors">
		<xsl:call-template name="person.name.list">
			<xsl:with-param name="person.list" select="db:bookinfo/db:authorgroup/db:editor"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="editorsEqual" select="$authors=$editors"/>
	
	<xsl:if test="not($editorsEqual)">
		<div id="title_page_collection_editors">
			<strong><xsl:text>Collection edited by: </xsl:text></strong>
                        <span>
        			<xsl:copy-of select="$editors"/>
                        </span>
		</div>
	</xsl:if>
	<div id="title_page_module_authors">
		<strong>
			<xsl:choose>
				<xsl:when test="$editorsEqual">
					<xsl:text>By: </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Content authors: </xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</strong>
                <span>
        		<xsl:copy-of select="$authors"/>
        		</span>
	</div>
	<xsl:if test="db:bookinfo/db:authorgroup/db:othercredit[@class='translator']">
		<div id="title_page_translators">
			<strong><xsl:text>Translated by: </xsl:text></strong>
                        <span>
        			<xsl:call-template name="person.name.list">
        				<xsl:with-param name="person.list" select="db:bookinfo/db:authorgroup/db:othercredit[@class='translator']"/>
        			</xsl:call-template>
                        </span>
		</div>
	</xsl:if>
	<xsl:if test="db:bookinfo/ext:derived-from">
		<div id="title_page_derivation">
                        <strong><xsl:text>Based on: </xsl:text></strong>
                        <span>
	        		<xsl:apply-templates select="db:bookinfo/ext:derived-from/db:title/node()"/>
        			<xsl:call-template name="cnx.cuteurl">
        				<xsl:with-param name="url" select="db:bookinfo/ext:derived-from/@url"/>
        			</xsl:call-template>
                        </span>
                        <xsl:text>.</xsl:text>
		</div>
	</xsl:if>
	<div id="title_page_url">
		<strong><xsl:text>Online: </xsl:text></strong>
                <span>
        			<xsl:call-template name="cnx.cuteurl">
        				<xsl:with-param name="url" select="concat(@ext:url,'/')"/>
        			</xsl:call-template>
                </span>
	</div>
	<xsl:if test="$cnx.iscnx != 0">
                <div id="portal_statement">
        		<div id="portal_title"><span><xsl:text>CONNEXIONS</xsl:text></span></div>
        		<div id="portal_location"><span><xsl:text>Rice University, Houston, Texas</xsl:text></span></div>
                </div>
	</xsl:if>
        <div id="copyright_page">
        	<xsl:if test="db:bookinfo/db:authorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor']">
        		<div id="copyright_statement">
        			<xsl:text>This selection and arrangement of content as a collection is copyrighted by </xsl:text>
        			<xsl:call-template name="person.name.list">
        				<xsl:with-param name="person.list" select="db:bookinfo/db:authorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor']"/>
        			</xsl:call-template>
        			<xsl:text>.</xsl:text>
        			<!-- TODO: use the XSL param "generate.legalnotice.link" to chunk the notice into a separate file -->
        			<xsl:apply-templates mode="titlepage.mode" select="db:bookinfo/db:legalnotice"/>
        		</div>
        	</xsl:if>
        	<xsl:if test="not(db:bookinfo/db:authorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor'])">
        		<xsl:call-template name="cnx.log"><xsl:with-param name="msg">WARNING: No copyright holders getting output under bookinfo for collection level.... weird.</xsl:with-param></xsl:call-template>
        	</xsl:if>
        	<xsl:if test="@ext:derived-url">
        		<div id="copyright_derivation">
        			<xsl:text>The collection was based on </xsl:text>
        			<xsl:call-template name="cnx.cuteurl">
        				<xsl:with-param name="url" select="@ext:derived-url"/>
        			</xsl:call-template>
        		</div>
        	</xsl:if>
        	<div id="copyright_revised">
        		<xsl:text>Collection structure revised: </xsl:text>
         	<xsl:apply-templates mode="titlepage.mode" select="db:bookinfo/db:pubdate/text()"/>
        	</div>
        	<div id="copyright_attribution">
        		<xsl:text>For copyright and attribution information for the modules contained in this collection, see the "</xsl:text>
                <xsl:call-template name="simple.xlink">
                        <xsl:with-param name="linkend" select="$attribution.section.id"/>
                        <xsl:with-param name="content">
                        	<xsl:text>Attributions</xsl:text>
                        </xsl:with-param>
                </xsl:call-template>
        		<xsl:text>" section at the end of the collection.</xsl:text>
        	</div>
        </div>
</xsl:template>

<xsl:template name="cnx.cuteurl">
	<xsl:param name="url"/>
	<xsl:param name="text" select="$url"/>
	<xsl:text> &lt;</xsl:text>
	<a href="{$url}">
    	<xsl:copy-of select="$text"/>
    </a>
    <xsl:text>&gt;</xsl:text>
</xsl:template>

</xsl:stylesheet>
