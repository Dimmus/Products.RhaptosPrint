<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:d="http://docbook.org/ns/docbook"
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
<xsl:include href="bibtex2epub.xsl"/>

<!-- Number the sections 1 level deep. See http://docbook.sourceforge.net/release/xsl/current/doc/html/ -->
<xsl:param name="section.autolabel" select="1"></xsl:param>
<xsl:param name="section.autolabel.max.depth">1</xsl:param>
<xsl:param name="chunk.section.depth" select="0"></xsl:param>
<xsl:param name="chunk.first.sections" select="0"></xsl:param>

<xsl:param name="section.label.includes.component.label">1</xsl:param>
<xsl:param name="xref.with.number.and.title">0</xsl:param>
<xsl:param name="toc.section.depth">0</xsl:param>
<xsl:param name="chunker.output.omit-xml-declaration" select="'yes'"/>
<xsl:param name="chunker.output.encoding" select="'ASCII'"/>

<!-- Prevent a TOC from being generated for module EPUBs -->
<xsl:param name="generate.toc">
  <xsl:choose>
    <xsl:when test="db:book/@ext:element='module'">
      book nop
    </xsl:when>
    <xsl:otherwise>
      book toc,title
    </xsl:otherwise>
  </xsl:choose>
</xsl:param>

<!-- Defined in docbook-xsl/epub/docbook.xsl but the default does not use the $html.ext defined in docbook -->
<xsl:param name="epub.cover.html" select="concat('cover', $html.ext)" />

<xsl:output indent="yes" method="xml" omit-xml-declaration="yes" encoding="ASCII"/>

<!-- Output the PNG with the baseline info -->
<xsl:template match="@pmml2svg:baseline-shift">
    <xsl:attribute name="style">
        <!-- Set the height and width in the style so it scales? -->
        <xsl:text>width:</xsl:text>
        <xsl:value-of select="../@width"/>
        <xsl:text>; height:</xsl:text>
        <xsl:value-of select="../@depth"/>
        <xsl:text>; </xsl:text>
          <xsl:text>vertical-align:-</xsl:text>
          <xsl:value-of select="." />
          <xsl:text>pt;</xsl:text>
      </xsl:attribute>
</xsl:template>


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
    <span class="label">
      <xsl:text>(</xsl:text>
      <xsl:apply-templates select="." mode="label.markup"/>
      <xsl:text>)</xsl:text>
    </span>
    <xsl:apply-templates/>
  </div>
</xsl:template>

<!-- Output equation titles instead of squishing them, as done in docbook (xsl/html/formal.xsl) -->
<xsl:template match="db:equation/db:title">
    <div class="equation-title">
        <b>
            <xsl:apply-templates/>
        </b>
    </div>
</xsl:template>


<!-- Output para titles as blocks instead of inline, as done in docbook -->
<xsl:template match="db:formalpara/db:title">
    <div class="para-title">
        <b>
            <xsl:apply-templates/>
        </b>
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
      
      <!-- Put cover image first -->
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

      <!-- Make sure the title page is the 1st item in the spine after the cover -->
      <xsl:if test="db:book">
          <xsl:element namespace="http://www.idpf.org/2007/opf" name="itemref">
            <xsl:attribute name="idref">
              <xsl:value-of select="generate-id(db:book)"/>
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
<xsl:template mode="opf.metadata" match="db:authorgroup[@role='all' or not(@role)]">
    <xsl:apply-templates mode="opf.metadata" select="node()"/>
</xsl:template>


<xsl:template name="cnx.authors.match">
    <xsl:param name="set1"/>
    <xsl:param name="set2"/>
    <xsl:param name="count" select="1"/>
    <xsl:choose>
        <!-- Base case (end of list) -->
        <xsl:when test="$count > count($set1)"/>
        <!-- Mismatch because set sizes don't match -->
        <xsl:when test="count($set1) != count($set2)">
            <xsl:text>set-size-diff=</xsl:text>
            <xsl:value-of select="count($set2) - count($set1)"/>
        </xsl:when>
        <!-- Check and recurse -->
        <xsl:otherwise>
	        <xsl:variable name="id" select="$set1[$count]/@ext:user-id"/>
	        <xsl:if test="not($set2[@ext:user-id=$id])">
	            <xsl:value-of select="$id"/>
	            <xsl:text>|</xsl:text>
	        </xsl:if>
	        <xsl:call-template name="cnx.authors.match">
	            <xsl:with-param name="set1" select="$set1"/>
	            <xsl:with-param name="set2" select="$set2"/>
	            <xsl:with-param name="count" select="$count+1"/>
	        </xsl:call-template>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<!-- Customize the title page.
    TODO: All of these can be made nicer using gentext and the %t replacements
 -->
<xsl:template name="book.titlepage">
    <!-- To handle the case where we're generating a module epub -->
    <xsl:variable name="collectionAuthorgroup" select="db:bookinfo/db:authorgroup[@role='collection' or not(../db:authorgroup[@role='collection'])]"/>
    <xsl:variable name="collectionAuthors" select="$collectionAuthorgroup/db:author"/>
    <xsl:variable name="moduleAuthors" select="db:bookinfo/db:authorgroup[@role='module' or not(../db:authorgroup[@role='module'])]/db:author"/>
    <!-- Only modules have editors -->
    <xsl:variable name="editors" select="db:bookinfo/db:authorgroup[not(@role)]/db:editor"/>
    <xsl:variable name="translators" select="$collectionAuthorgroup/db:othercredit[@class='translator']"/>
    <xsl:variable name="licensors" select="$collectionAuthorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor']"/>
    <xsl:variable name="authorsMismatch">
        <xsl:call-template name="cnx.authors.match">
            <xsl:with-param name="set1" select="$collectionAuthors"/>
            <xsl:with-param name="set2" select="$moduleAuthors"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="showCollectionAuthors" select="$authorsMismatch != ''"/>
    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Displaying separate collections authors on title page? <xsl:value-of select="$showCollectionAuthors"/></xsl:with-param></xsl:call-template>

    <h2>
        <xsl:value-of select="db:bookinfo/db:title/text()"/>
    </h2>

    <xsl:if test="$showCollectionAuthors">
        <xsl:call-template name="cnx.log"><xsl:with-param name="msg">DEBUG: Authors mismatch because of <xsl:value-of select="$authorsMismatch"/></xsl:with-param></xsl:call-template>
        <div id="title_page_collection_editors">
            <strong><xsl:text>Collection edited by: </xsl:text></strong>
            <span>
                <xsl:call-template name="person.name.list">
                    <xsl:with-param name="person.list" select="$collectionAuthors"/>
                </xsl:call-template>
            </span>
        </div>
    </xsl:if>
    <div id="title_page_module_authors">
        <strong>
            <xsl:choose>
                <xsl:when test="not($showCollectionAuthors)">
                    <xsl:text>By: </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Content authors: </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </strong>
        <span>
            <xsl:call-template name="person.name.list">
                <xsl:with-param name="person.list" select="$moduleAuthors"/>
            </xsl:call-template>
        </span>
    </div>
    <!-- Only for modules -->
    <xsl:if test="$editors">
        <div>
            <strong><xsl:text>Edited by: </xsl:text></strong>
            <span>
                <xsl:call-template name="person.name.list">
                    <xsl:with-param name="person.list" select="$editors"/>
                </xsl:call-template>
            </span>
        </div>
    </xsl:if>
    <xsl:if test="$translators">
        <div id="title_page_translators">
            <strong><xsl:text>Translated by: </xsl:text></strong>
            <span>
                <xsl:call-template name="person.name.list">
                    <xsl:with-param name="person.list" select="$translators"/>
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
            <xsl:text>.</xsl:text>
        </span>
        </div>
    </xsl:if>
    <div id="title_page_url">
        <strong><xsl:text>Online: </xsl:text></strong>
        <span>
            <xsl:call-template name="cnx.cuteurl">
                <xsl:with-param name="url" select="concat(@ext:url, '/')"/>
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
        <xsl:if test="$licensors">
            <div id="copyright_statement">
                <xsl:choose>
                    <xsl:when test="@ext:element='module'">
                        <xsl:text>This module is copyrighted by </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>This selection and arrangement of content as a collection is copyrighted by </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
                
                <xsl:call-template name="person.name.list">
                    <xsl:with-param name="person.list" select="$licensors"/>
                </xsl:call-template>
                <xsl:text>.</xsl:text>
            </div>
        </xsl:if>
        <xsl:if test="not($licensors)">
            <xsl:call-template name="cnx.log"><xsl:with-param name="msg">WARNING: No copyright holders getting output under bookinfo for collection level.... weird.</xsl:with-param></xsl:call-template>
        </xsl:if>
        <!-- TODO: use the XSL param "generate.legalnotice.link" to chunk the notice into a separate file -->
        <xsl:apply-templates mode="titlepage.mode" select="db:bookinfo/db:legalnotice"/>
        <xsl:if test="@ext:derived-url">
            <div id="copyright_derivation">
                <xsl:text>The collection was based on </xsl:text>
                <xsl:call-template name="cnx.cuteurl">
                    <xsl:with-param name="url" select="@ext:derived-url"/>
                </xsl:call-template>
            </div>
        </xsl:if>
        <div id="copyright_revised">
            <xsl:choose>
                <xsl:when test="@ext:element='module'">
                    <xsl:text>Module revised: </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Collection structure revised: </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            
            <!-- FIXME: Should read "August 10, 2009".  But for now, leaving as "2009/08/10" and chopping off the rest of the time/timezone stuff. -->
            <xsl:value-of select="substring-before(normalize-space(db:bookinfo/db:pubdate/text()),' ')"/>
        </div>
        <xsl:if test="not(@ext:element='module')">
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
	    </xsl:if>
    </div>
</xsl:template>

<xsl:template name="cnx.cuteurl">
    <xsl:param name="url"/>
    <xsl:param name="text">
        <xsl:value-of select="$url"/>
    </xsl:param>
    <xsl:text> &lt;</xsl:text>
    <a href="{$url}">
        <xsl:copy-of select="$text"/>
    </a>
    <xsl:text>&gt;</xsl:text>
</xsl:template>

<!-- Docbook generates "???" when it cannot generate text for a db:xref. Instead, we print the name of the closest enclosing element. -->
<xsl:template match="*" mode="xref-to">
    <xsl:variable name="orig">
        <xsl:apply-imports/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$orig='???'">
            <xsl:choose>
                <xsl:when test="@ext:element">
		            <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Using @ext:element for xref text: <xsl:value-of select="local-name()"/> is <xsl:value-of select="@ext:element"/></xsl:with-param></xsl:call-template>
                    <xsl:value-of select="@ext:element"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Using element name for xref text: <xsl:value-of select="local-name()"/></xsl:with-param></xsl:call-template>
                    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">DEBUG: Using element name for xref text: <xsl:value-of select="local-name()"/> id=<xsl:value-of select="(@id|@xml:id)[1]"/></xsl:with-param></xsl:call-template>
                    <xsl:value-of select="local-name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$orig"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
<xsl:template match="db:xref" mode="xref-to">
    <xsl:text>link</xsl:text>
</xsl:template>
<!-- Support linking to c:media or c:media/c:image. See m12196 -->
<xsl:template match="db:mediaobject[not(db:objectinfo/db:title)]|db:inlinemediaobject[not(db:objectinfo/db:title)]" mode="xref-to">
    <xsl:choose>
        <xsl:when test="db:imageobject">
            <xsl:text>image</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>media</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- FIXME: This template an exact copy from the docbook copy.  The only change was for the namespace ("d:" to "db:") and white space.  
     This mysteriously makes @start-value work (and gets us closer to @number-style working).
     But it really shouldn't be necessary to copy the template verbatim.  Not sure why it doesn't work w/o this template here.  -->
<xsl:template match="db:orderedlist">
  <xsl:variable name="start">
    <xsl:call-template name="orderedlist-starting-number"/>
  </xsl:variable>
  <xsl:variable name="numeration">
    <xsl:call-template name="list.numeration"/>
  </xsl:variable>
  <xsl:variable name="type">
    <xsl:choose>
      <xsl:when test="$numeration='arabic'">1</xsl:when>
      <xsl:when test="$numeration='loweralpha'">a</xsl:when>
      <xsl:when test="$numeration='lowerroman'">i</xsl:when>
      <xsl:when test="$numeration='upperalpha'">A</xsl:when>
      <xsl:when test="$numeration='upperroman'">I</xsl:when>
      <!-- What!? This should never happen -->
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>Unexpected numeration: </xsl:text>
          <xsl:value-of select="$numeration"/>
        </xsl:message>
        <xsl:value-of select="1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <div>
    <xsl:call-template name="common.html.attributes"/>
    <xsl:call-template name="anchor"/>
    <xsl:if test="db:title">
      <xsl:call-template name="formal.object.heading"/>
    </xsl:if>
    <!-- Preserve order of PIs and comments -->
    <xsl:apply-templates 
        select="*[not(self::db:listitem
                  or self::db:title
                  or self::db:titleabbrev)]
                |comment()[not(preceding-sibling::db:listitem)]
                |processing-instruction()[not(preceding-sibling::db:listitem)]"/>
    <xsl:choose>
      <xsl:when test="@inheritnum='inherit' and ancestor::db:listitem[parent::db:orderedlist]">
        <table border="0">
          <xsl:call-template name="generate.class.attribute"/>
          <col align="{$direction.align.start}" valign="top"/>
          <tbody>
            <xsl:apply-templates 
                mode="orderedlist-table"
                select="db:listitem
                        |comment()[preceding-sibling::db:listitem]
                        |processing-instruction()[preceding-sibling::db:listitem]"/>
          </tbody>
        </table>
      </xsl:when>
      <xsl:otherwise>
        <ol>
          <xsl:call-template name="generate.class.attribute"/>
          <xsl:if test="$start != '1'">
            <xsl:attribute name="start">
              <xsl:value-of select="$start"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="$numeration != ''">
            <xsl:attribute name="type">
              <xsl:value-of select="$type"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="@spacing='compact'">
            <xsl:attribute name="compact">
              <xsl:value-of select="@spacing"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates 
                select="db:listitem
                        |comment()[preceding-sibling::db:listitem]
                        |processing-instruction()[preceding-sibling::db:listitem]"/>
        </ol>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>


<!-- Originally taken from docbook-xsl/xhtml-1_1/html.xsl -->
<!-- In HTML mode, <a/> tags cannot be nested. For example
     <a href="http://x.org"><a id="1"/>...</a>
     will cause the @href to be dropped.
 -->
<xsl:template name="anchor">
  <xsl:param name="node" select="."/>
  <xsl:param name="conditional" select="1"/>
  <xsl:variable name="id">
    <xsl:call-template name="object.id">
      <xsl:with-param name="object" select="$node"/>
    </xsl:call-template>
  </xsl:variable>
  <xsl:if test="not($node[parent::db:blockquote])">
    <xsl:if test="$conditional = 0 or $node/@id or $node/@xml:id">
<!-- Added the case where the current node is a db:link -->
<xsl:choose>
    <xsl:when test="self::db:link">
        <xsl:call-template name="cnx.log"><xsl:with-param name="msg">DEBUG: Instead of generating an anchor, just set the @xml:id</xsl:with-param></xsl:call-template>
        <xsl:attribute name="xml:id">
            <xsl:value-of select="$id"/>
        </xsl:attribute>
    </xsl:when>
    <xsl:otherwise>
        <xsl:call-template name="cnx.log"><xsl:with-param name="msg">DEBUG: Inserting a span tag instead of an anchor tag for <xsl:value-of select="local-name($node)"/></xsl:with-param></xsl:call-template>
        <!-- Webkit parses the HTML incorrectly if a span is self-closed -->
        <span id="{$id}"><xsl:text> </xsl:text></span>
    </xsl:otherwise>
</xsl:choose>
    </xsl:if>
  </xsl:if>
</xsl:template>

<!-- Label module EPUB abstracts as more user-friendly "Summary" instead of "Abstract" (conforms to rest of our site). -->
<!-- Copied from docbook/xsl/common/titles.xsl and edited.  -->
<xsl:template match="db:abstract" mode="title.markup">
  <xsl:param name="allow-anchors" select="0"/>
  <xsl:choose>
    <xsl:when test="db:title|db:info/db:title">
      <xsl:apply-templates select="(db:title|db:info/db:title)[1]" mode="title.markup">
        <xsl:with-param name="allow-anchors" select="$allow-anchors"/>
      </xsl:apply-templates>
    </xsl:when>
    <xsl:otherwise>
      <!-- TODO: generate 'Summary' with gentext -->
      <xsl:text>Summary</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Taken from docbook-xsl/epub/graphics.xsl . Added default for "alt" param. -->
  <!-- we can't deal with no img/@alt, because it's required. Try grabbing a title before it instead (hopefully meaningful) --> 
  <xsl:template name="process.image.attributes"> 
    <!-- BEGIN customization -->
    <xsl:param name="alt" select="ancestor::d:mediaobject/d:textobject[d:phrase]|ancestor::d:inlinemediaobject/d:textobject[d:phrase]"/>
    <!-- END customization -->
    <xsl:param name="html.width"/> 
    <xsl:param name="html.depth"/> 
    <xsl:param name="longdesc"/> 
    <xsl:param name="scale"/> 
    <xsl:param name="scalefit"/> 
    <xsl:param name="scaled.contentdepth"/> 
    <xsl:param name="scaled.contentwidth"/> 
    <xsl:param name="viewport"/> 
 
    <xsl:choose> 
      <xsl:when test="@contentwidth or @contentdepth"> 
        <!-- ignore @width/@depth, @scale, and @scalefit if specified --> 
        <xsl:if test="@contentwidth and $scaled.contentwidth != ''"> 
          <xsl:attribute name="width"> 
            <xsl:value-of select="$scaled.contentwidth"/> 
          </xsl:attribute> 
        </xsl:if> 
        <xsl:if test="@contentdepth and $scaled.contentdepth != ''"> 
          <xsl:attribute name="height"> 
            <xsl:value-of select="$scaled.contentdepth"/> 
          </xsl:attribute> 
        </xsl:if> 
      </xsl:when> 
 
      <xsl:when test="number($scale) != 1.0"> 
        <!-- scaling is always uniform, so we only have to specify one dimension --> 
        <!-- ignore @scalefit if specified --> 
        <xsl:attribute name="width"> 
          <xsl:value-of select="$scaled.contentwidth"/> 
        </xsl:attribute> 
      </xsl:when> 
 
      <xsl:when test="$scalefit != 0"> 
        <xsl:choose> 
          <xsl:when test="contains($html.width, '%')"> 
            <xsl:choose> 
              <xsl:when test="$viewport != 0"> 
                <!-- The *viewport* will be scaled, so use 100% here! --> 
                <xsl:attribute name="width"> 
                  <xsl:value-of select="'100%'"/> 
                </xsl:attribute> 
              </xsl:when> 
              <xsl:otherwise> 
                <xsl:attribute name="width"> 
                  <xsl:value-of select="$html.width"/> 
                </xsl:attribute> 
              </xsl:otherwise> 
            </xsl:choose> 
          </xsl:when> 
 
          <xsl:when test="contains($html.depth, '%')"> 
            <!-- HTML doesn't deal with this case very well...do nothing --> 
          </xsl:when> 
 
          <xsl:when test="$scaled.contentwidth != '' and $html.width != ''                         and $scaled.contentdepth != '' and $html.depth != ''"> 
            <!-- scalefit should not be anamorphic; figure out which direction --> 
            <!-- has the limiting scale factor and scale in that direction --> 
            <xsl:choose> 
              <xsl:when test="$html.width div $scaled.contentwidth &gt;                             $html.depth div $scaled.contentdepth"> 
                <xsl:attribute name="height"> 
                  <xsl:value-of select="$html.depth"/> 
                </xsl:attribute> 
              </xsl:when> 
              <xsl:otherwise> 
                <xsl:attribute name="width"> 
                  <xsl:value-of select="$html.width"/> 
                </xsl:attribute> 
              </xsl:otherwise> 
            </xsl:choose> 
          </xsl:when> 
 
          <xsl:when test="$scaled.contentwidth != '' and $html.width != ''"> 
            <xsl:attribute name="width"> 
              <xsl:value-of select="$html.width"/> 
            </xsl:attribute> 
          </xsl:when> 
 
          <xsl:when test="$scaled.contentdepth != '' and $html.depth != ''"> 
            <xsl:attribute name="height"> 
              <xsl:value-of select="$html.depth"/> 
            </xsl:attribute> 
          </xsl:when> 
        </xsl:choose> 
      </xsl:when> 
    </xsl:choose> 
 
    <!-- AN OVERRIDE --> 
    <xsl:if test="not(@format ='SVG')"> 
      <xsl:attribute name="alt"> 
        <xsl:choose> 
          <xsl:when test="$alt != ''"> 
            <xsl:value-of select="normalize-space($alt)"/> 
          </xsl:when> 
          <xsl:when test="preceding::d:title[1]"> 
            <xsl:value-of select="normalize-space(preceding::d:title[1])"/> 
          </xsl:when> 
          <xsl:otherwise> 
            <xsl:text>(missing alt)</xsl:text> 
          </xsl:otherwise> 
        </xsl:choose> 
      </xsl:attribute> 
    </xsl:if> 
    <!-- END OF OVERRIDE --> 
 
    <xsl:if test="$longdesc != ''"> 
      <xsl:attribute name="longdesc"> 
        <xsl:value-of select="$longdesc"/> 
      </xsl:attribute> 
    </xsl:if> 
 
    <xsl:if test="@align and $viewport = 0"> 
      <xsl:attribute name="style"><xsl:text>text-align: </xsl:text> 
        <xsl:choose> 
          <xsl:when test="@align = 'center'">middle</xsl:when> 
          <xsl:otherwise> 
            <xsl:value-of select="@align"/> 
          </xsl:otherwise> 
        </xsl:choose> 
      </xsl:attribute> 
    </xsl:if> 
  </xsl:template> 

</xsl:stylesheet>

