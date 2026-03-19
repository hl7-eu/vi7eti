<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:local="http://vi7eti.net/xsltfunctions"
    exclude-result-prefixes="xs fhir xhtml"
    version="2.0">
    
    <!--<xsl:output method="xhtml" doctype-system="about:legacy-compat" omit-xml-declaration="yes"/>-->
    <xsl:output method="xhtml" omit-xml-declaration="yes"/>
       
    <!-- derived parameters -->
    <xsl:param name="isListofCompositions" select="count(fhir:Bundle/fhir:entry[1]/fhir:resource/fhir:List)>0"/>
    
    <!-- global: get entries for later reference -->
    <xsl:variable name="entries" select="if ($isListofCompositions) then fhir:Bundle/fhir:entry/fhir:resource/fhir:Bundle/fhir:entry else fhir:Bundle/fhir:entry"/>
    
    <xsl:template match="fhir:Bundle">
        <!-- 
            get composition,
            if this is a List Bundle, get the first composition
            if this is a flat Bundle with only one composition, take it.
        -->
        <xsl:variable name="composition">
            <xsl:choose>
                <xsl:when test="fhir:entry[1]/fhir:resource/fhir:Composition">
                    <xsl:copy-of select="fhir:entry[1]/fhir:resource/fhir:Composition"/>
                </xsl:when>
                <xsl:when test="fhir:entry[1]/fhir:resource/fhir:List">
                    <xsl:copy-of select="fhir:entry/fhir:resource/fhir:Bundle/fhir:entry[1]/fhir:resource/fhir:Composition"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- error -->
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- emit xhtml -->
        <!-- if this is json source, offer the "show source" feature -->
        <div>
            <xsl:apply-templates select="$composition"/>
            <!-- if additional js is available, include it -->
        </div>
    </xsl:template>
    
    <xsl:template match="fhir:Composition">
        
        <xsl:param name="position" select="position()"/>
        
        <header class="preamble__header">
            <h1>
                <xsl:value-of select="fhir:title/@value"/>
            </h1>
        </header>
        <!--
        <section class="accordion container2">
            
            <div class="accordion__container2" tabindex="-1">
                
          
                <xsl:if test="$position > 0">
                    <xsl:call-template name="doDislaimer"/>
                    <xsl:call-template name="back2index"/>
                    <xsl:call-template name="doTestandExample"/>
                </xsl:if>
-->
        <xsl:call-template name="productDetailsCard"/>
        <xsl:call-template name="regAuthCard"/>
        
        <!-- process preamble(s) and sections -->
        <xsl:apply-templates select="fhir:section" mode="preamble">
            <xsl:with-param name="level" select="2"/>
        </xsl:apply-templates>
        
        <xsl:call-template name="organizationCard"/>
                <!--
            </div>

        </section>
        -->
        
    </xsl:template>
    
    <!-- and fhir:code/fhir:coding/fhir:system/@value = 'https://spor.ema.europa.eu/rmswi/' -->
    <!-- allowed section codes: 100000155538, 200000029791 -->
    <xsl:variable name="s1codes" select="('100000155538', '200000029791', '200000029850', '200000029861', '200000029894',
        '200000029791', '200000029850')"/>
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code/@value = $s1codes]" mode="preamble">
        <xsl:param name="level"/>
        
        <xsl:variable name="h" select="$level"/>
        
        <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
            <header class="accordion__header">
                <span class="mdi mdi-plus accordion__icon"> </span>
                <xsl:element name="{concat('h', $h)}">
                    <xsl:attribute name="class" select="'accordion__title'"/>
                    <xsl:value-of select="fhir:title/@value"/>
                </xsl:element>
            </header>
            <div class="accordion__content">
                <div class="accordion__description">
                    <xsl:apply-templates select="fhir:text/xhtml:div"/>
                </div>
                <xsl:apply-templates select="fhir:section" mode="subsection">
                    <xsl:with-param name="level" select="$level+1"/>
                </xsl:apply-templates>
            </div>
        </div>

    </xsl:template>
    
    <!-- allowed section codes:
    <xsl:template match="fhir:section[not(fhir:emptyReason)][fhir:code/fhir:coding/fhir:code/@value = $s2codes]">-->
    <xsl:variable name="s2codes" select="(
        '100000155538', '200000029792', '200000029793',
        '200000029797', '200000029798', '200000029799', '200000029800', '200000029801',
        '200000044347', '200000029802', '200000029803', '200000029805',' 200000029806', '200000044333',
        '200000029792', '200000029793', '200000029797', '200000029798', '200000029799', '200000029800',
        '200000029801'
        )"/>
    <xsl:template match="fhir:section" mode="subsection">
        <xsl:param name="level"/>
        <xsl:variable name="h" select="$level"/>
        <xsl:variable name="show__content__as__paragraphs" select="$level > 4"/>

            <xsl:choose>
                <xsl:when test="$show__content__as__paragraphs">
                    <div xmlns="http://www.w3.org/1999/xhtml" class="vi7eti_regular">
                        <xsl:element name="{concat('h', $h)}">
                            <xsl:attribute name="class" select="'accordion__title'"/>
                            <xsl:value-of select="fhir:title/@value"/>
                        </xsl:element>
                        <xsl:apply-templates select="fhir:text/xhtml:div"/>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                        <header class="accordion__header">
                            <span class="mdi mdi-plus accordion__icon"> </span>
                            <xsl:element name="{concat('h', $h)}">
                                <xsl:attribute name="class" select="'accordion__title'"/>
                                <xsl:value-of select="fhir:title/@value"/>
                            </xsl:element>
                        </header>
                        <div class="accordion__content">
                            <div class="accordion__description">
                                <xsl:apply-templates select="fhir:text/xhtml:div"/>
                                <!--<xsl:apply-templates select="fhir:section[position()&lt;3]" mode="preamble">
                        <xsl:with-param name="level" select="$level+1"/>
                    </xsl:apply-templates>-->
                                <xsl:apply-templates select="fhir:section" mode="subsection">
                                    <xsl:with-param name="level" select="$level+1"/>
                                </xsl:apply-templates>
                            </div>
                        </div>
                    </div>
                </xsl:otherwise>
            </xsl:choose>

    </xsl:template>
    
    <xsl:template match="fhir:text">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fhir:*"/>
    
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="xhtml:img">
        <img>
            <xsl:copy-of select="@*[not(local-name()='src')]"/>
            <xsl:variable name="srcorig" select="replace(@src,'#','')"/>
            <xsl:for-each select="//fhir:Binary[fhir:id/@value=$srcorig]">
                <xsl:attribute name="src" select="concat('data:',fhir:contentType/@value,';base64, ',fhir:data/@value)"/>
            </xsl:for-each>
        </img>
    </xsl:template>
    
    <xsl:template name="organizationCard">
        <xsl:if test="$entries/fhir:resource/fhir:Organization">
            <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-factory accordion__coicon"> </span>
                    <h3 class="accordion__title">Organizations</h3>
                </header>
                <div class="accordion__content">
                    <div class="accordion__description">
                        <table class="epi__report organization">
                            <thead>
                                <tr>
                                    <th style="width=30%;">Organization</th>
                                    <th style="width=20%;">Type</th>
                                    <th style="width=50%;">Information</th>
                                </tr>
                            </thead>
                            <tbody>
                                <xsl:for-each select="$entries/fhir:resource/fhir:Organization">
                                    <tr>
                                        <td>
                                            <strong><xsl:value-of select="fhir:name/@value"/></strong>
                                        </td>
                                        <td>
                                            <xsl:value-of select="fhir:type/fhir:coding/fhir:display/@value"/>
                                        </td>
                                        <td>
                                            <xsl:value-of select="fhir:contact/fhir:address/fhir:text/@value"/>
                                        </td>
                                    </tr>
                                </xsl:for-each>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="productDetailsCard">
        <xsl:if test="$entries/fhir:resource/fhir:Ingredient">
            <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-pill accordion__coicon"> </span>
                    <h3 class="accordion__title">Product Details</h3>
                </header>
                <xsl:choose>
                    <xsl:when test="count($entries/fhir:resource/fhir:MedicinalProductDefinition/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value) = 0">
                        <div class="accordion__content">
                            <div class="accordion__description">No product details available</div>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="accordion__content">
                            <div class="accordion__description">
                                <table class="epi__report ingredients">
                                    <thead>
                                        <tr>
                                            <th style="width:20%;">Product</th>
                                            <th style="width:80%;">
                                                <div class="brace-padding">Ingredients</div>
                                            </th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="$entries/fhir:resource/fhir:MedicinalProductDefinition/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value">
                                            <xsl:variable name="lmvFestId" select="."/>
                                            <xsl:variable name="firstMpd" select="$entries/fhir:resource/fhir:MedicinalProductDefinition[fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi' and fhir:value/@value = $lmvFestId]][1]"/>
                                            <xsl:variable name="firstMpdId" select="$firstMpd/fhir:id/@value"/>
                                            <xsl:variable name="allIngedients" select="$entries/fhir:resource/fhir:Ingredient[fhir:for/fhir:reference/@value = concat('MedicinalProductDefinition/', $firstMpdId)]"/>
                                            <tr>
                                                <td>
                                                    <xsl:value-of select="$firstMpd/fhir:name/fhir:productName/@value"/>
                                                </td>
                                                <td>
                                                    <div class="brace-left">
                                                        <div class="brace-padding">
                                                            <!-- two rounds, one for the active ingredient roles and one for the other -->
                                                            <xsl:variable name="cai">
                                                                <xsl:for-each select="$allIngedients[ lower-case(fhir:role/fhir:coding/fhir:display/@value) ='active']">
                                                                    <fhir:Ingredient rank="{local:valueunitscore(fhir:substance/fhir:strength/fhir:presentationQuantity)}">
                                                                        <xsl:copy-of select="*" copy-namespaces="yes"/>
                                                                    </fhir:Ingredient>
                                                                </xsl:for-each>
                                                            </xsl:variable>
                                                            <div class="ingredient__type">
                                                                Active
                                                            </div>
                                                            <ul class="list-unstyled w550">
                                                                <xsl:apply-templates select="$cai/*[@rank]">
                                                                    <xsl:sort select="@rank" order="descending"/>
                                                                </xsl:apply-templates>
                                                            </ul>
                                                            <div class="ingredient__type">Other</div>
                                                            <ul class="list-unstyled w550">
                                                                <xsl:apply-templates select="$allIngedients[ lower-case(fhir:role/fhir:coding/fhir:display/@value) !='active']">
                                                                    <xsl:sort select="fhir:substance/fhir:code/fhir:concept/fhir:coding/fhir:display/@value"/>
                                                                </xsl:apply-templates>
                                                            </ul>
                                                        </div>
                                                    </div>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                                <table class="epi__report authorized_presentations">
                                    <thead>
                                        <tr>
                                            <th colspan="5">Authorized Presentations</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="$entries/fhir:resource/fhir:MedicinalProductDefinition/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value">
                                            <xsl:variable name="lmvFestId" select="."/>
                                            <xsl:variable name="firstMpd" select="$entries/fhir:resource/fhir:MedicinalProductDefinition[fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi' and fhir:value/@value = $lmvFestId]][1]"/>
                                            <tr>
                                                <xsl:if test="position() mod 2 = 1">
                                                    <xsl:attribute name="class" select="'gray'"/>
                                                </xsl:if>
                                                <th>(Invented)&#xA0;Name</th>
                                                <th>Strength</th>
                                                <th>MA&#xA0;(EU)&#xA0;number</th>
                                                <th colspan="2">PHPID</th>
                                            </tr>
                                            <tr>
                                                <xsl:if test="position() mod 2 = 1">
                                                    <xsl:attribute name="class" select="'gray'"/>
                                                </xsl:if>
                                                <td>
                                                    <xsl:value-of select="$firstMpd/fhir:name/fhir:part[fhir:type/fhir:coding[fhir:system/@value='https://spor.ema.europa.eu/lists/220000000000'][fhir:code/@value='220000000002']]/fhir:part/@value"/>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="$firstMpd/fhir:name/fhir:part[fhir:type/fhir:coding[fhir:system/@value='https://spor.ema.europa.eu/lists/220000000000'][fhir:code/@value='220000000004']]/fhir:part/@value"/>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="$firstMpd/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value"/>
                                                </td>
                                                <td colspan="2">
                                                    <xsl:value-of select="$firstMpd/fhir:identifier[fhir:system/@value = 'https://www.who-umc.org/phpid']/fhir:value/@value"/>
                                                </td>
                                            </tr>
                                            <tr>
                                                <xsl:if test="position() mod 2 = 1">
                                                    <xsl:attribute name="class" select="'gray'"/>
                                                </xsl:if>
                                                <th> </th>
                                                <th>Pharmaceutical&#xA0;Form</th>
                                                <th>Route&#xA0;of&#xA0;Administration</th>
                                                <th>Immediate&#xA0;Packaging</th>
                                                <th>Pack&#xA0;Size</th>
                                            </tr>
                                            <tr>
                                                <xsl:if test="position() mod 2 = 1">
                                                    <xsl:attribute name="class" select="'gray'"/>
                                                </xsl:if>
                                                <td> </td>
                                                <td>
                                                    <xsl:value-of select="$firstMpd/fhir:name/fhir:part[fhir:type/fhir:coding[fhir:system/@value='https://spor.ema.europa.eu/lists/220000000000'][fhir:code/@value='220000000005']]/fhir:part/@value"/>
                                                </td>
                                                <td> </td>
                                                <td> </td>
                                                <td> </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:function name="local:valueunitscore">
        <!-- 
                if (fhir:substance/fhir:strength/fhir:presentationQuantity/fhir:value/@value castable as xs:integer)
                    then xs:integer(fhir:substance/fhir:strength/fhir:presentationQuantity/fhir:value/@value)
                    else 0"
        -->
        <xsl:param name="prQ"/> <!-- shall be a fhir:presentationQuantity -->
        <xsl:choose>
            <xsl:when test="$prQ/fhir:value/@value castable as xs:long">
                <xsl:variable name="tmp1" select="xs:long($prQ/fhir:value/@value)" as="xs:long"/>
                <xsl:variable name="tmp2" as="xs:long">
                    <xsl:choose>
                        <xsl:when test="$prQ/fhir:unit/@value = 'kg' or  $prQ/fhir:code/@value = 'kg'">
                            <xsl:value-of select="$tmp1 * 1000000000"/>
                        </xsl:when>
                        <xsl:when test="$prQ/fhir:unit/@value = 'g' or  $prQ/fhir:code/@value = 'g'">
                            <xsl:value-of select="$tmp1 * 1000000"/>
                        </xsl:when>
                        <xsl:when test="$prQ/fhir:unit/@value = 'mg' or  $prQ/fhir:code/@value = 'mg'">
                            <xsl:value-of select="$tmp1 * 1000"/>
                        </xsl:when>
                        <xsl:when test="$prQ/fhir:unit/@value = 'ug' or  $prQ/fhir:code/@value = 'ug'">
                            <xsl:value-of select="$tmp1 * 1"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$tmp1 * 1"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="1000000000000 + $tmp2"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'0'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="fhir:strength">
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="fhir:Ingredient">
        <li>
            <!-- id (unused) -->
            <!--<xsl:value-of select="fhir:id/@value"/>-->

            <!-- show substance name -->
            <xsl:value-of select="fhir:substance/fhir:code/fhir:concept/fhir:coding/fhir:display/@value"/>
            
            <!-- show strength -->
            <xsl:apply-templates select="fhir:substance/fhir:strength"/>
            
            <!-- show role -->
            <span class="ingredient__role">
                <!-- role -->
                <xsl:value-of select="fhir:role/fhir:coding/fhir:display/@value"/>
            </span>
            
        </li>
    </xsl:template>
    
    <xsl:template match="fhir:presentationQuantity">
        <xsl:if test="fhir:comparator">
            <xsl:value-of select="fhir:comparator/@value"/>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="fhir:value/@value"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="fhir:unit/@value | fhir:code/@value"/>
    </xsl:template>
    
    <xsl:template match="fhir:presentationRatio">
        <xsl:value-of select="fhir:numerator/fhir:value/@value"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="fhir:numerator/fhir:unit/@value | fhir:numerator/fhir:code/@value"/>
        <xsl:if test="fhir:denominator">
            <xsl:text> / </xsl:text>
            <xsl:value-of select="fhir:denominator/fhir:value/@value"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="fhir:denominator/fhir:unit/@value | fhir:denominator/fhir:code/@value"/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="fhir:presentationRatioRange">
        <!-- No examples in scope -->
    </xsl:template>
    
    <xsl:template name="regAuthCard">
        <xsl:if test="$entries/fhir:resource/fhir:RegulatedAuthorization">
            <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-office-building-marker-outline accordion__coicon"> </span>
                    <h3 class="accordion__title">Authorisation Details</h3>
                </header>
                <xsl:choose>
                    <xsl:when test="count($entries/fhir:resource/fhir:RegulatedAuthorization) = 0">
                        <div class="accordion__content">
                            <div class="accordion__description">No regulated authorization information available</div>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <div class="accordion__content">
                            <div class="accordion__description">
                                <table class="epi__report authorisation_details">
                                    <thead>
                                        <tr>
                                            <!--<th>Product Identifier</th>-->
                                            <th>Authorisation number</th>
                                            <th>Region</th>
                                            <th>Marketing authorisation holder</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <xsl:for-each select="$entries/fhir:resource/fhir:RegulatedAuthorization">
                                            <xsl:variable name="pdId" select=" substring-after(fhir:subject/fhir:reference/@value, '/')"/>
                                            <xsl:variable name="pd" select="$entries/fhir:resource/fhir:PackagedProductDefinition[fhir:id/@value = $pdId] | $entries/fhir:resource/fhir:MedicinalProductDefinition[fhir:id/@value = $pdId]"/>
                                            <xsl:variable name="mohId" select=" substring-after(fhir:holder/fhir:reference/@value, '/')"/>
                                            <xsl:variable name="moh" select="$entries/fhir:resource/fhir:Organization[fhir:id/@value = $mohId]"/>
                                            <tr>
                                                <!--
                                        <td>
                                            <xsl:value-of select="$pd/fhir:identifier[fhir:system/@value='https://www.who-umc.org/phpid']/fhir:value/@value"/>
                                        </td>
                                        -->
                                                <td>
                                                    <xsl:value-of select="fhir:identifier/fhir:value/@value"/>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="fhir:region/fhir:coding/fhir:display/@value"/>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="$moh/fhir:name/@value"/>
                                                    <xsl:if test="$moh/fhir:identifier[fhir:system/@value='https://spor.ema.europa.eu/omswi']">
                                                        (<xsl:value-of select="$moh/fhir:identifier[fhir:system/@value='https://spor.ema.europa.eu/omswi']/fhir:value/@value"/>)
                                                    </xsl:if>        
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </xsl:otherwise>
                </xsl:choose>
                
            </div>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>