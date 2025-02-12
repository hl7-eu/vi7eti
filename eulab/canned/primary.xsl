<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs fhir xhtml"
    version="2.0">
    
    <xsl:output method="xhtml" doctype-system="about:legacy-compat" omit-xml-declaration="yes"/>
    
    <xsl:param name="additionalCSS" select="'styles.css'"/>
    <xsl:param name="additionalJS" select="'main.js'"/>
    <xsl:param name="JSONsource"/>
    
    <!-- global: get entries for later reference -->
    <xsl:param name="entries" select="fhir:Bundle/fhir:entry"/>
    
    <xsl:template match="fhir:Bundle">
        
        <!-- get composition -->
        <xsl:variable name="composition" select="$entries/fhir:resource/fhir:Composition"/>

        <!-- emit xhtml -->
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <meta charset="UTF-8"> </meta>
                <meta name="viewport" content="width=device-width, initial-scale=1.0"> </meta>
                <!--=============== ICONS ===============-->
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@mdi/font@7.4.47/css/materialdesignicons.min.css"> </link>
                <!--=============== CSS/JS ==============-->
                <link rel="stylesheet" href="stylesmain.css"> </link>
                <xsl:if test="string-length($additionalCSS) > 0">
                    <link rel="stylesheet" href="{$additionalCSS}"> </link>
                </xsl:if>
                <xsl:if test="string-length($additionalJS) > 0">
                    <script src="{$additionalJS}"> </script>
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
                <section xmlns="http://www.w3.org/1999/xhtml" class="accordion container">
                    <div class="accordion__container">
                        <xsl:call-template name="doDislaimer"/>
                        <xsl:call-template name="back2index"/>
                        <xsl:call-template name="doTestandExample"/>
                        
                        <header class="preamble__header">
                            <h1>
                                <xsl:value-of select="$composition/fhir:title/@value"/>
                            </h1>
                        </header>
                                                
                        <div class="preamble__content">
                            
                            <!-- table with patient, ordering authority and lab authority -->
                            <table class="top__header__table">
                                <tr>
                                    <td width="33%">
                                        <!-- column for the patient -->
                                        <xsl:apply-templates select="fhir:entry/fhir:resource/fhir:Patient"/>
                                    </td>
                                    <td width="33%">
                                        <!-- column for the specimen -->
                                        <xsl:apply-templates select="$composition/fhir:author"/>
                                    </td>
                                    <td width="33%">
                                        <!-- column for the lab and requester -->
                                        <xsl:apply-templates select="(fhir:entry/fhir:resource/fhir:ServiceRequest)[1]"/>
                                        <xsl:apply-templates select="(fhir:entry/fhir:resource/fhir:Specimen)[1]"/>
                                    </td>
                                </tr>
                            </table>

                            <xsl:apply-templates select="$composition"/>
                            
                        </div>
                    </div>
                </section>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template match="fhir:Composition">
        <section xmlns="http://www.w3.org/1999/xhtml" class="accordion container">
            
            <xsl:if test="fhir:section[1]/fhir:title/@value != 'Laboratory Report'">
                <h3>
                    <xsl:value-of select="fhir:section[1]/fhir:title/@value"/>
                </h3>
            </xsl:if>
            
            <xsl:apply-templates select="fhir:section/fhir:section">
                <xsl:with-param name="lvl" select="2"/>
            </xsl:apply-templates>

        </section>
    </xsl:template>
    
    <xsl:template match="fhir:Patient">
        <!-- return a table with patient data -->
        <table class="meta__header">
            <tr>
                <th colspan="2">Patient</th>
            </tr>
            <tr>
                <td>Name:</td>
                <td>
                    <xsl:apply-templates select="fhir:name"/>
                </td>
            </tr>
            <tr>
                <td>DOB:</td>
                <td>
                    <xsl:call-template name="format-date">
                        <xsl:with-param name="date" select="fhir:birthDate/@value"/>
                    </xsl:call-template>
                    <xsl:text> (Age: </xsl:text>
                    <xsl:choose>
                        <xsl:when test="month-from-date(current-date()) > month-from-date(fhir:birthDate/@value) or month-from-date(current-date()) = month-from-date(fhir:birthDate/@value) and day-from-date(current-date()) >= day-from-date(fhir:birthDate/@value)">
                            <xsl:value-of select="year-from-date(current-date()) - year-from-date(fhir:birthDate/@value)" />
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="year-from-date(current-date()) - year-from-date(fhir:birthDate/@value) - 1" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>)</xsl:text>
                </td>
            </tr>
            <tr>
                <td>Gender:</td>
                <td>
                    <xsl:value-of select="fhir:gender/@value"/>
                </td>
            </tr>
            <tr>
                <td>Address:</td>
                <td>
                    <xsl:apply-templates select="fhir:address"/>
                </td>
            </tr>
            <tr>
                <td>ID (ECI):</td>
                <td>
                    <xsl:value-of select="fhir:identifier[fhir:system/@value='http://ec.europa.eu/identifier/eci']/fhir:value/@value"/>
                </td>
            </tr>
        </table>
    </xsl:template>
    
    <xsl:template match="fhir:author">
        <!-- return tables with lab report date and author data -->
        
        <table class="meta__header">
            <thead>
                <tr>
                    <th colspan="2">Report</th>
                </tr>
            </thead>
            <tr>
                <td>
                    <strong>Date:</strong>
                </td>
                <td>
                    <strong>
                        <xsl:call-template name="format-date">
                            <xsl:with-param name="date" select="$entries/fhir:resource/fhir:Composition/fhir:date/@value"/>
                        </xsl:call-template>
                    </strong>
                </td>
            </tr>
        </table>
            
        <table class="meta__header">
            <thead>
                <tr>
                    <th>Laboratory</th>
                </tr>
            </thead>
            <tr>
                <td>
                    <xsl:for-each select="fhir:reference">
                        <xsl:variable name="rid" select="@value"/>
                        <xsl:for-each select="$entries[fhir:fullUrl/@value = $rid]/fhir:resource">
                            <xsl:choose>
                                <xsl:when test="fhir:PractitionerRole">
                                    <xsl:variable name="prid" select="fhir:PractitionerRole/fhir:practitioner/fhir:reference/@value"/>
                                    <xsl:for-each select="$entries[fhir:fullUrl/@value = $prid]/fhir:resource/fhir:Practitioner">
                                        <xsl:apply-templates select="fhir:name"/>
                                        <div>
                                            <xsl:apply-templates select="fhir:address"/>
                                        </div>
                                    </xsl:for-each>
                                </xsl:when>
                                <xsl:when test="fhir:Practitioner">
                                    <xsl:apply-templates select="fhir:name"/>
                                    <div>
                                        <xsl:apply-templates select="fhir:address"/>
                                    </div>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
    </xsl:template>
    
    <xsl:template match="fhir:Specimen">
        <!-- return a table with specimen data -->
        <table class="meta__header">
            <thead>
                <tr>
                    <th colspan="2">Specimen</th>
                </tr>
            </thead>
            <tr>
                <td>Collected:</td>
                <td>
                    <xsl:call-template name="format-date">
                        <xsl:with-param name="date" select="fhir:collection/fhir:collectedDateTime/@value"/>
                    </xsl:call-template>
                </td>
            </tr>
        </table>
    </xsl:template>
    
    <xsl:template match="fhir:ServiceRequest">
        <!-- return a table with lab report requester -->
        <xsl:if test="fhir:requester">
            <table class="meta__header">
                <thead>
                    <tr>
                        <th colspan="2">Requested by</th>
                    </tr>
                </thead>
                <xsl:for-each select="fhir:requester/fhir:reference">
                    <xsl:variable name="rid" select="@value"/>
                    <xsl:for-each select="$entries[fhir:fullUrl/@value = $rid]/fhir:resource">
                        <xsl:choose>
                            <xsl:when test="fhir:PractitionerRole">
                                <xsl:variable name="prid" select="fhir:PractitionerRole/fhir:organization/fhir:reference/@value"/>
                                <xsl:for-each select="$entries[fhir:fullUrl/@value = $prid]/fhir:resource/fhir:Organization">
                                    <tr>
                                        <td>
                                            <div>
                                                <xsl:value-of select="fhir:name/@value"/>
                                            </div>
                                            <div>
                                                <xsl:apply-templates select="fhir:address"/>
                                            </div>
                                        </td>
                                    </tr>
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="fhir:Organization">
                                <xsl:apply-templates select="fhir:name"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </table>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="fhir:name">
        <xsl:for-each select="fhir:prefix">
            <xsl:value-of select="@value"/>
            <xsl:text> </xsl:text>
        </xsl:for-each>
        <strong>
            <xsl:value-of select="fhir:family/@value"/>
        </strong>
        <xsl:text>, </xsl:text>
        <xsl:for-each select="fhir:given">
            <xsl:value-of select="@value"/>
        </xsl:for-each>
        <xsl:for-each select="fhir:suffix">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="@value"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="fhir:address">
        <xsl:for-each select="fhir:line">
            <div>
                <xsl:value-of select="@value"/>
            </div>
        </xsl:for-each>
        <div>
            <xsl:value-of select="fhir:postalCode/@value"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="fhir:city/@value"/>
            <xsl:if test="string-length(fhir:country/@value) > 0">
                <xsl:text> (</xsl:text>
                <xsl:value-of select="fhir:country/@value"/>
                <xsl:text>)</xsl:text>
            </xsl:if>
        </div>
    </xsl:template>
    
    <xsl:template match="fhir:DiagnosticReport">
        <!-- return a table with patient data -->
        <table>
            <thead>
                <tr>
                    <th colspan="2">Patient</th>
                </tr>
            </thead>
            <tr>
                <td>Name:</td>
                <td>
                    <strong>
                        <xsl:value-of select="fhir:name/fhir:family/@value"/>
                    </strong>
                    <xsl:text>, </xsl:text>
                    <xsl:for-each select="fhir:name/fhir:given">
                        <xsl:value-of select="@value"/>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
    </xsl:template>
    
    <xsl:template match="fhir:section">
        <xsl:param name="lvl"/>
        <xsl:copy-of select="fhir:text"/>
    </xsl:template>
    
    <xsl:template name="doDislaimer">
        <div class="disclaimer">
            Disclaimer: These web pages are not intended to be used as a source of information on patient care.
            <div>The laboratory reports are clinically reasonable, but synthetic and contain AI generated content.</div>
        </div>
    </xsl:template>
    
    <xsl:template name="back2index">
        <div id="popupDialog">
            <textarea rows="32" cols="70" id="jsonsource"/>
            <button onclick="togglePopup()">
                Close
            </button>
        </div>
        <div>
            <button onclick="togglePopup();">Show source</button>
            <button onclick="location.href=window.location.origin+window.location.pathname;">Back to overview</button>
        </div>
    </xsl:template>
    
    <xsl:template name="doTestandExample">
        <div class="testonly">FOR TEST AND EXAMPLE PURPOSES ONLY! This is a live rendition of the original source file.</div>
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
            <xsl:variable name="src" select="replace(@src,'#','')"/>
            <xsl:for-each select="//fhir:Binary[fhir:id/@value=$src]">
                <xsl:attribute name="src" select="concat('data:',fhir:contentType/@value,';base64, ',fhir:data/@value)"/>
            </xsl:for-each>
        </img>
    </xsl:template>
    
    <xsl:template name="format-date">
        <xsl:param name="date"/>
        <!-- day -->
        <xsl:value-of select="substring($date, 9, 2)"/>
        <xsl:text>-</xsl:text>
        <!-- month -->
        <xsl:variable name="m" select="substring($date, 6, 2)"/>
        <xsl:choose>
            <xsl:when test="$m='01'">
                <xsl:text>JAN</xsl:text>
            </xsl:when>
            <xsl:when test="$m='02'">
                <xsl:text>FEB</xsl:text>
            </xsl:when>
            <xsl:when test="$m='03'">
                <xsl:text>MAR</xsl:text>
            </xsl:when>
            <xsl:when test="$m='04'">
                <xsl:text>APR</xsl:text>
            </xsl:when>
            <xsl:when test="$m='05'">
                <xsl:text>MAY</xsl:text>
            </xsl:when>
            <xsl:when test="$m='06'">
                <xsl:text>JUN</xsl:text>
            </xsl:when>
            <xsl:when test="$m='07'">
                <xsl:text>JUL</xsl:text>
            </xsl:when>
            <xsl:when test="$m='08'">
                <xsl:text>AUG</xsl:text>
            </xsl:when>
            <xsl:when test="$m='09'">
                <xsl:text>SEP</xsl:text>
            </xsl:when>
            <xsl:when test="$m='10'">
                <xsl:text>OCT</xsl:text>
            </xsl:when>
            <xsl:when test="$m='11'">
                <xsl:text>NOV</xsl:text>
            </xsl:when>
            <xsl:when test="$m='12'">
                <xsl:text>DEC</xsl:text>
            </xsl:when>
        </xsl:choose>
        <xsl:text>-</xsl:text>
        <!-- year -->
        <xsl:value-of select="substring($date, 1, 4)"/>
    </xsl:template>
    
</xsl:stylesheet>