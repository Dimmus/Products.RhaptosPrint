<xsl:stylesheet version="1.0"
xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:import href="c2p-files/cnxmathmlc2p.xsl"/>
<!-- 
<xsl:import href="c2p-files/ctop-cnxmathmlc2p.xsl"/>
 -->

<xsl:param name="cnx.math.imaginaryi" select="'&#x2148;'"/>

<!-- 
  UGLY HACKery. mathmlc2p.xsl creates prefixed elements by using escaping
  (so the prefix isn't really bound to anything)
  So, we force a prefix on the mml:math element.
 -->
<xsl:template match="mml:math">
	<mml:math>
		<xsl:apply-templates select="@*|node()"/>
	</mml:math>
<!-- 
	<xsl:text> ctop:[</xsl:text>
	   <xsl:apply-templates mode="c2p" select="."/>
    <xsl:text>]</xsl:text>
 -->
</xsl:template>

<!-- Override (in ctop.xsl) 4.4.3.3 divide --> 
<xsl:template mode="c2p" match="mml:apply[*[1][self::mml:divide]]"> 
  <xsl:param name="p" select="0"/>
  <xsl:variable name="this-p" select="3"/>
  <mml:mfrac>
    <xsl:apply-templates mode="c2p" select="*[2]"/>
    <xsl:apply-templates mode="c2p" select="*[3]"/>
  </mml:mfrac> 
</xsl:template> 

<!-- Override (in ctop.xsl) 4.4.12.1 integers --> 
<xsl:template mode="c2p" match="mml:integers"> 
<mml:mi mathvariant="double-struck">&#x2124;<!-- Open face Z --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.2 reals --> 
<xsl:template mode="c2p" match="mml:reals"> 
<mml:mi mathvariant="double-struck">&#x211D;<!-- Open face R --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.3 rationals --> 
<xsl:template mode="c2p" match="mml:rationals"> 
<mml:mi mathvariant="double-struck">&#x211A;<!-- Open face Q --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.4 naturalnumbers --> 
<xsl:template mode="c2p" match="mml:naturalnumbers"> 
<mml:mi mathvariant="double-struck">&#x2115;<!-- Open face N --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.5 complexes --> 
<xsl:template mode="c2p" match="mml:complexes"> 
<mml:mi mathvariant="double-struck">&#x2102;<!-- Open face C --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.6 primes --> 
<xsl:template mode="c2p" match="mml:primes"> 
<mml:mi mathvariant="double-struck">&#x2119;<!-- Open face P --></mml:mi> 
</xsl:template> 
 
<!-- Override (in ctop.xsl) 4.4.12.7 exponentiale --> 
<xsl:template mode="c2p" match="mml:exponentiale"> 
  <mml:mi>&#x2147;<!-- exponential e--></mml:mi> 
</xsl:template> 
 
<!-- 4.4.12.8 imaginaryi --> 
<xsl:template mode="c2p" match="mml:imaginaryi"> 
  <mml:mi><xsl:value-of select="$cnx.math.imaginaryi"/><!-- imaginary i--></mml:mi> 
</xsl:template> 


</xsl:stylesheet>