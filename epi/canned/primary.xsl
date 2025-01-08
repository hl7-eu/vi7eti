<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs fhir xhtml"
    version="2.0">
    
    <xsl:output method="xhtml" doctype-system="about:legacy-compat"/>
    
    <xsl:param name="additionalCSS" select="'styles.css'"/>
    <xsl:param name="additionalJS" select="'main.js'"/>
    <xsl:param name="JSONsource"/>
    
    <xsl:template match="fhir:Bundle">
        <!-- get composition -->
        <xsl:variable name="composition" select="fhir:entry[1]/fhir:resource/fhir:Composition"/>
        <!-- emit xhtml -->
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <meta charset="UTF-8"> </meta>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"> </meta>
                <!--=============== ICONS ===============-->
                <link href="https://cdn.jsdelivr.net/npm/@mdi/font@7.4.47/css/materialdesignicons.min.css" rel="stylesheet"> </link>
                <!--=============== CSS/JS ==============-->
                <link rel="stylesheet" href="stylesmain.css"> </link>
                <xsl:if test="string-length($additionalCSS) > 0">
                    <link rel="stylesheet" href="{$additionalCSS}"> </link>
                </xsl:if>
                <xsl:if test="string-length($JSONsource) > 0">
                    <script>
                        function init(j) {
                        
                        loadJSON(j, function(response) {
                        
                        // Parse JSON string into object
                        var json = JSON.parse(response);
                        
                        // Transforms the JSON object into a readable string.
                        var json_string = JSON.stringify(json, undefined, 2);
                        
                        const textar =
                        document.getElementById(
                        "jsonsource"
                        );
                        textar.innerHTML = json_string
                        });
                        };
                    </script>
                </xsl:if>
                <title>
                    <xsl:value-of select="$composition/fhir:title/@value"/>
                </title>
            </head>
            <body>
                <xsl:if test="string-length($JSONsource) > 0">
                    <xsl:attribute name="onLoad" select="concat('init(', '&quot;', $JSONsource, '&quot;', ')')"/>
                </xsl:if>
                <xsl:apply-templates select="$composition"/>
                <xsl:if test="string-length($additionalJS) > 0">
                    <script src="{$additionalJS}"> </script>
                </xsl:if>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="fhir:Composition">
        <section xmlns="http://www.w3.org/1999/xhtml" class="accordion container">
            
            <div class="accordion__container">
                
                <xsl:call-template name="doDislaimer"/>
                
                <!--<xsl:call-template name="back2index"/>-->
                
                <xsl:call-template name="doTestandExample"/>

                <header class="preamble__header">
                    <h1>
                        <xsl:value-of select="fhir:title/@value"/>
                    </h1>
                </header>
                
                <xsl:call-template name="productDetailsCard"/>
                <xsl:call-template name="regAuthCard"/>
                                
                <!-- process preamble(s) and sections -->
                <xsl:apply-templates select="fhir:section" mode="preamble">
                        <xsl:with-param name="level" select="2"/>
                </xsl:apply-templates>
                
            </div>

        </section>
                
    </xsl:template>
    
    <xsl:template name="doDislaimer">
        <div xmlns="http://www.w3.org/1999/xhtml" class="disclaimer">
            Disclaimer: These web pages are not intended to be used as a source of information on medicines.
            The web pages are not kept up to date and are for demonstration purposes only.
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines
            or the package leaflet of your medicine.
        </div>
    </xsl:template>
    
    <xsl:template name="back2index">
        <div xmlns="http://www.w3.org/1999/xhtml">
            <button onclick="location.href=window.location.origin+window.location.pathname;">Back to overview</button>
        </div>
    </xsl:template>

    <xsl:template name="doTestandExample">
        <div xmlns="http://www.w3.org/1999/xhtml" class="testonly">FOR TEST AND EXAMPLE PURPOSES ONLY!</div>
    </xsl:template>
    
    <!-- and fhir:code/fhir:coding/fhir:system/@value = 'https://spor.ema.europa.eu/rmswi/' -->
    <xsl:template match="fhir:section[fhir:code/fhir:coding/fhir:code/@value = '100000155538']" mode="preamble">
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
                <xsl:apply-templates select="fhir:section">
                    <xsl:with-param name="level" select="$level+1"/>
                </xsl:apply-templates>
            </div>
        </div>

    </xsl:template>
    
    <xsl:template match="fhir:section[not(fhir:emptyReason)][fhir:code/fhir:coding/fhir:code/@value = '100000155538']">
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
                    <xsl:apply-templates select="fhir:section[position()&lt;3]" mode="preamble">
                        <xsl:with-param name="level" select="$level+1"/>
                    </xsl:apply-templates>
                </div>
            </div>

        </div>

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
    
    <xsl:template name="productDetailsCard">
        <xsl:if test="/fhir:Bundle/fhir:entry/fhir:resource/fhir:Ingredient">
            <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-pill accordion__coicon"> </span>
                    <h3 class="accordion__title">Product Details</h3>
                </header>
                
                <div class="accordion__content">
                    <div class="accordion__description">
                        <table class="epi__report ingredients">
                            <thead>
                                <tr>
                                    <th style="width:50%;">Product</th>
                                    <th style="width:50%;">Ingredients</th>
                                </tr>
                            </thead>
                            <tbody>
                                <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:MedicinalProductDefinition/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value">
                                    <xsl:variable name="lmvFestId" select="."/>
                                    <xsl:variable name="firstMpd" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:MedicinalProductDefinition[fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi' and fhir:value/@value = $lmvFestId]][1]"/>
                                    <tr>
                                        <td>
                                            <xsl:value-of select="$firstMpd/fhir:name/fhir:productName/@value"/>
                                        </td>
                                        <td>
                                            <ul class="list-unstyled">
                                                <xsl:variable name="firstMpdId" select="$firstMpd/fhir:id/@value"/>
                                                <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:Ingredient[fhir:for/fhir:reference/@value = concat('MedicinalProductDefinition/', $firstMpdId)]">
                                                    <li>
                                                        <!-- id (unused) -->
                                                        <!--<xsl:value-of select="fhir:id/@value"/>-->
                                                        
                                                        <!-- role -->
                                                        <xsl:variable name="irole" select="fhir:role"/>
                                                        
                                                        <!-- substance -->
                                                        <xsl:variable name="isubstance" select="fhir:substance"/>
                                                        
                                                        <!--
                                                        <xsl:variable name="sdId" select="substring-after(fhir:substance/fhir:code/fhir:reference/fhir:reference/@value, '/')"/>
                                                        <xsl:variable name="sd" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:SubstanceDefinition[fhir:id/@value = $sdId]"/>
                                                        <xsl:value-of select="$sd/fhir:name[fhir:language/fhir:coding/fhir:code/@value = 'en']/fhir:name/@value"/>
                                                        -->
                                                        
                                                        <!-- show substance name -->
                                                        <xsl:value-of select="$isubstance/fhir:code/fhir:concept/fhir:coding/fhir:display/@value"/>
                                                                                                                
                                                        <!-- show strength -->
                                                        <xsl:apply-templates select="fhir:substance/fhir:strength"/>
                                                        
                                                        <!-- show role -->
                                                        <span class="ingredient__role">
                                                            <xsl:value-of select="$irole/fhir:coding/fhir:display/@value"/>
                                                        </span>

                                                    </li>
                                                </xsl:for-each>
                                            </ul>
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
                                <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:MedicinalProductDefinition/fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi']/fhir:value/@value">
                                    <xsl:variable name="lmvFestId" select="."/>
                                    <xsl:variable name="firstMpd" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:MedicinalProductDefinition[fhir:identifier[fhir:system/@value = 'https://spor.ema.europa.eu/pmswi' and fhir:value/@value = $lmvFestId]][1]"/>
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
            
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="fhir:strength">
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
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
        <xsl:if test="/fhir:Bundle/fhir:entry/fhir:resource/fhir:RegulatedAuthorization">
            <div xmlns="http://www.w3.org/1999/xhtml" class="accordion__item vi7eti_regular">
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-office-building-marker-outline accordion__coicon"> </span>
                    <h3 class="accordion__title">Authorisation Details</h3>
                </header>
                
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
                                <xsl:for-each select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:RegulatedAuthorization">
                                    <xsl:variable name="pdId" select=" substring-after(fhir:subject/fhir:reference/@value, '/')"/>
                                    <xsl:variable name="pd" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:PackagedProductDefinition[fhir:id/@value = $pdId] | /fhir:Bundle/fhir:entry/fhir:resource/fhir:MedicinalProductDefinition[fhir:id/@value = $pdId]"/>
                                    <xsl:variable name="mohId" select=" substring-after(fhir:holder/fhir:reference/@value, '/')"/>
                                    <xsl:variable name="moh" select="/fhir:Bundle/fhir:entry/fhir:resource/fhir:Organization[fhir:id/@value = $mohId]"/>
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
            </div>
        </xsl:if>
    </xsl:template>
    
</xsl:stylesheet>