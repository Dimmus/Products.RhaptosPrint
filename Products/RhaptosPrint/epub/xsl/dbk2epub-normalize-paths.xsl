<?xml version="1.0" ?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:c="http://cnx.rice.edu/cnxml"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:md="http://cnx.rice.edu/mdml/0.4" xmlns:bib="http://bibtexml.sf.net/"
  xmlns:xi="http://www.w3.org/2001/XInclude"
  xmlns:ext="http://cnx.org/ns/docbook+"
  xmlns:cnxorg="http://cnx.rice.edu/system-info"
  version="1.0">

<!-- This file:
     * Ensures paths to images inside modules are correct (using @xml:base)
     //* Adds a @ext:first-letter attribute to glossary entries so they can be organized into a book-level glossary 
     * Adds an Attribution section at the end of the book
     * Uses ext:persons element to eventually call docbook-xsl/common/common.xsl:"person.name.list" and render the names
 -->

<xsl:import href="param.xsl"/>
<xsl:import href="debug.xsl"/>
<xsl:import href="ident.xsl"/>

<!-- Strip 'em for html generation -->
<xsl:template match="@xml:base"/>

<!-- Make image paths point into the module directory -->
<xsl:template match="@fileref">
    <xsl:variable name="prefix" select="substring-before(ancestor::db:section[@xml:base]/@xml:base, '/')"/>
    <xsl:attribute name="fileref">
        <xsl:if test="$prefix != ''">
            <xsl:value-of select="$prefix"/>
            <xsl:text>/</xsl:text>
        </xsl:if>
        <xsl:value-of select="."/>
    </xsl:attribute>
</xsl:template>

<!-- Creating an authors list for collections (STEP 1). Just collect all the authors (with duplicates) -->
<!-- Create 3 authorgroups for all authors, only collection authors, and for module authors (preserve ordering) -->
<xsl:template match="/db:book/db:bookinfo">
    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Generating 3 book-level db:authorgroups @role="all|collection|module"</xsl:with-param></xsl:call-template>
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <db:authorgroup role="all">
            <xsl:for-each select="..//db:authorgroup[not(ancestor::db:bibliography)]/db:*">
                <xsl:call-template name="ident"/>
            </xsl:for-each>
        </db:authorgroup>
        <db:authorgroup role="collection">
            <xsl:for-each select="db:authorgroup/db:*">
                <xsl:call-template name="ident"/>
            </xsl:for-each>
        </db:authorgroup>
        <db:authorgroup role="module">
            <xsl:for-each select="../*[not(self::db:bookinfo)]//db:authorgroup[not(ancestor::db:bibliography)]/db:*">
                <xsl:call-template name="ident"/>
            </xsl:for-each>
        </db:authorgroup>
        <xsl:apply-templates select="node()"/>
    </xsl:copy>
</xsl:template>

<xsl:template match="db:authorgroup">
    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Discarding db:authorgroup whose grandparent is <xsl:value-of select="local-name(../..)"/></xsl:with-param></xsl:call-template>
</xsl:template>

<!-- DEAD: Removed in favor of module-level glossaries
<!- - Overloading the file to add glossary metadata - ->
<xsl:template match="db:glossentry">
    <!- - Find the 1st character. Used later in the transform to generate a glossary alphbetically - ->
    <xsl:variable name="letters">
        <xsl:apply-templates mode="glossaryletters" select="db:glossterm/node()"/>
    </xsl:variable>
    <xsl:variable name="firstLetter" select="translate(substring(normalize-space($letters),1,1),'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">DEBUG: Glossary: firstLetter="<xsl:value-of select="$firstLetter"/>" of "<xsl:value-of select="normalize-space($letters)"/>"</xsl:with-param></xsl:call-template>
    <db:glossentry ext:first-letter="{$firstLetter}">
        <xsl:apply-templates select="@*|node()"/>
    </db:glossentry>
</xsl:template>
<!- - Helper template to recursively find the text in a glossary term - ->
<xsl:template mode="glossaryletters" select="*">
    <xsl:apply-templates mode="glossaryletters"/>
</xsl:template>
<xsl:template mode="glossaryletters" select="text()">
    <xsl:value-of select="."/>
</xsl:template>
-->


<!-- Add an attribution section with all the modules at the end of the book -->
<xsl:template match="db:book">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
        <db:appendix>
            <xsl:attribute name="xml:id">
                <xsl:value-of select="$attribution.section.id"/>
            </xsl:attribute>
            <db:title>Attributions</db:title>
            <xsl:for-each select=".//db:prefaceinfo|.//db:chapterinfo|.//db:sectioninfo|.//db:appendixinfo">
                <xsl:variable name="id">
                    <xsl:call-template name="cnx.id">
                        <xsl:with-param name="object" select=".."/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="url">
                    <xsl:value-of select="$cnx.url"/>
                    <xsl:value-of select="$id"/>
                    <xsl:text>/</xsl:text>
                    <!-- Some modules don't have md:version set (db:edition), so pull it from the collection -->
                    <xsl:choose>
                       <xsl:when test="../@cnxorg:version-at-this-collection-version">
                           <xsl:value-of select="../@cnxorg:version-at-this-collection-version"/>
                       </xsl:when>
                       <!-- Could have been xincluded in a db:preface -->
                       <xsl:when test="../../@cnxorg:version-at-this-collection-version">
                           <xsl:value-of select="../../@cnxorg:version-at-this-collection-version"/>
                       </xsl:when>
                       <xsl:when test="db:edition/text()">
                           <xsl:value-of select="db:edition/text()"/>
                       </xsl:when>
                       <xsl:otherwise>
                           <xsl:text>latest</xsl:text>
                       </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>/</xsl:text>
                </xsl:variable>
                <xsl:variable name="attributionId">
                    <xsl:text>book.attribution.</xsl:text>
                    <xsl:value-of select="$id"/>
                </xsl:variable>
                <db:para>
                    <xsl:attribute name="xml:id">
                        <xsl:value-of select="$attributionId"/>
                    </xsl:attribute>
                    <db:simplelist>
                        <db:member>
                            <xsl:apply-templates select="db:title/@*"/>
                            <xsl:text>Module: </xsl:text>
                            <db:link linkend="{$id}">
                                <xsl:apply-templates select="db:title/node()"/>
                            </db:link>
                        </db:member>
                        <db:member>
                            <xsl:text>By: </xsl:text>
                            <ext:persons>
                                <xsl:apply-templates select="db:authorgroup/db:author"/>
                            </ext:persons>
                        </db:member>
                        <xsl:if test="db:authorgroup/db:editor">
                            <db:member>
                                <xsl:text>Edited by: </xsl:text>
                                <ext:persons>
                                    <xsl:apply-templates select="db:authorgroup/db:editor"/>
                                </ext:persons>
                            </db:member>
                        </xsl:if>
                        <xsl:if test="db:authorgroup/db:othercredit[@class='translator']">
                            <db:member>
                                <xsl:text>Translated by: </xsl:text>
                                <ext:persons>
                                    <xsl:apply-templates select="db:authorgroup/db:othercredit[@class='translator']"/>
                                </ext:persons>
                            </db:member>
                        </xsl:if>
                        <db:member>
                            <xsl:text>URL: </xsl:text>
                            <db:ulink url="{$url}"><xsl:value-of select="$url"/></db:ulink>
                        </db:member>
                        <xsl:if test="db:authorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor' and *[name()!='db:contrib']]">
                            <!-- Max: The *[name()!='db:contrib'] is to make sure that the db:othercredit is actually populated with a user.  
                                 Can somebody be removed once we populate this info for 0.5 modules -->
                            <db:member>
                                <xsl:text>Copyright: </xsl:text>
                                <ext:persons>
                                    <xsl:apply-templates select="db:authorgroup/db:othercredit[@class='other' and db:contrib/text()='licensor']"/>
                                </ext:persons>
                            </db:member>
                        </xsl:if>
                        <xsl:if test="db:legalnotice">
                            <db:member>
                                <xsl:text>License: </xsl:text>
                                <xsl:apply-templates select="db:legalnotice/db:ulink"/>
                            </db:member>
                        </xsl:if>
                        <xsl:if test="not(db:legalnotice)">
                            <xsl:call-template name="cnx.log"><xsl:with-param name="msg">WARNING: Module contains no license info</xsl:with-param></xsl:call-template>
                        </xsl:if>
                    </db:simplelist>
                </db:para>
            </xsl:for-each>
        </db:appendix>
        <xsl:if test="$cnx.iscnx != 0">
            <db:colophon>
                <db:title>About Connexions</db:title>
                <db:para>
                    Since 1999, Connexions has been pioneering a global system where anyone can create course materials and make them fully accessible and easily reusable free of charge. We are a Web-based authoring, teaching and learning environment open to anyone interested in education, including students, teachers, professors and lifelong learners. We connect ideas and facilitate educational communities. Connexions's modular, interactive courses are in use worldwide by universities, community colleges, K-12 schools, distance learners, and lifelong learners. Connexions materials are in many languages, including English, Spanish, Chinese, Japanese, Italian, Vietnamese, French, Portuguese, and Thai. 
                </db:para>
            </db:colophon>
        </xsl:if>
    </xsl:copy>
</xsl:template>


<!-- Some modules don't have md:version set, so pull it from the collection -->
<xsl:template match="db:*[contains(local-name(), 'info') and parent::*[@cnxorg:version-at-this-collection-version] and not(db:edition)]">
    <xsl:call-template name="cnx.log"><xsl:with-param name="msg">INFO: Setting version of module using @cnxorg:version-at-this-collection-version since none was set</xsl:with-param></xsl:call-template>
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
        <db:edition>
            <xsl:value-of select="../@cnxorg:version-at-this-collection-version"/>
        </db:edition>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>
