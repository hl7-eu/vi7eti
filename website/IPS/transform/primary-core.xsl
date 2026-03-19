<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="xs fhir xhtml"
    version="2.0">
    
    <xsl:output method="xhtml" doctype-system="about:legacy-compat" omit-xml-declaration="yes"/>
    
    <xsl:param name="self"/>
    <xsl:param name="selfindex"/>
    <xsl:param name="focusname"/>
    <xsl:param name="additionalCSS" as="xs:anyURI"/>
    <xsl:param name="additionalJS" as="xs:anyURI"/>
    <xsl:param name="JSONsource" as="xs:anyURI"/>
    
    <!-- global: get entries for later reference -->
    <xsl:param name="entries" select="fhir:Bundle/fhir:entry"/>
    
    <xsl:template match="fhir:Bundle">
        
        <!-- get composition -->
        <xsl:variable name="composition" select="$entries/fhir:resource/fhir:Composition"/>

        <div>
            <!-- emit xhtml -->
                <!-- if this is json source, offer the "show source" feature -->
               
            <div class="accordion__item vi7eti_regular">
                <xsl:if test="string-length($JSONsource) > 0">
                    <xsl:attribute name="onLoad" select="concat('init(', '&quot;', $JSONsource, '&quot;', ')')"/>
                </xsl:if>
                <header class="accordion__header">
                    <span class="mdi mdi-plus accordion__icon"> </span>
                    <span class="mdi mdi-account-heart-outline accordion__coicon"> </span>
                    <h3 class="accordion__title">
                        <xsl:value-of select="$composition/fhir:title/@value"/>
                    </h3>
                </header>
                <div class="accordion__content">
                    <div class="accordion__description">
                        
                        <!-- table with patient, etc. -->
                        <table class="top__header__table">
                            <tr>
                                <td width="33%">
                                    <!-- column for the patient -->
                                    <xsl:apply-templates select="fhir:entry/fhir:resource/fhir:Patient"/>
                                </td>
                                <td width="33%">
                                    <!-- column for the author -->
                                    <xsl:apply-templates select="$composition/fhir:author"/>
                                </td>
                                <td width="33%">
                                    <!-- column for the IPS meta data -->
                                    <xsl:call-template name="IPSinfo">
                                        <xsl:with-param name="type" select="$composition/fhir:type"/>
                                        <xsl:with-param name="title" select="$composition/fhir:title/@value"/>
                                        <xsl:with-param name="date" select="$composition/fhir:date/@value"/>
                                    </xsl:call-template>
                                </td>
                            </tr>
                        </table>
                        
                        <xsl:apply-templates select="$composition"/>
                        
                    </div>
                </div>
                <!-- if additional js is available, include it -->
                <xsl:if test="string-length($additionalJS) > 0">
                    <script src="{$additionalJS}"> </script>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
    <xsl:template match="fhir:Composition">
        <section xmlns="http://www.w3.org/1999/xhtml" class="accordion scontainer">
          
            <xsl:apply-templates select="fhir:section">
                <xsl:with-param name="lvl" select="1"/>
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
                    <xsl:text> (age: </xsl:text>
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
                <td>ID:</td>
                <td>
                    <xsl:choose>
                        <xsl:when test="fhir:identifier[fhir:system/@value='http://ec.europa.eu/identifier/eci']/fhir:value/@value">
                            <xsl:value-of select="fhir:identifier[fhir:system/@value='http://ec.europa.eu/identifier/eci']/fhir:value/@value"/>
                            <xsl:text> (ECI)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="(fhir:identifier/fhir:value/@value)[1]"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </td>
            </tr>
        </table>
    </xsl:template>
    
    <xsl:template match="fhir:author">
        <!-- return a table with lab report author data -->
        <table class="meta__header">
            <thead>
                <tr>
                    <th colspan="2">Author</th>
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
                                    </xsl:for-each>
                                    <div>
                                        <xsl:variable name="orid" select="fhir:PractitionerRole/fhir:organization/fhir:reference/@value"/>
                                        <xsl:for-each select="$entries[fhir:fullUrl/@value = $orid]/fhir:resource/fhir:Organization">
                                            <xsl:value-of select="fhir:name/@value"/>
                                            <xsl:apply-templates select="fhir:address"/>
                                        </xsl:for-each>
                                    </div>
                                </xsl:when>
                                <xsl:when test="fhir:Practitioner">
                                    <xsl:apply-templates select="fhir:Practitioner/fhir:name"/>
                                </xsl:when>
                                <xsl:when test="fhir:Organization">
                                    <xsl:value-of select="fhir:Organization/fhir:name/@value"/>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:for-each>
                </td>
            </tr>
        </table>
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
    
    <xsl:template match="fhir:section">
        <xsl:param name="lvl"/>
        <h3>
            <xsl:value-of select="fhir:title/@value"/>
        </h3>
        <xsl:copy-of select="fhir:text/xhtml:div"/>
    </xsl:template>
    
    <xsl:template name="doTestandExample">
        <div class="testonly">FOR TEST AND EXAMPLE PURPOSES ONLY!</div>
    </xsl:template>
    
    <xsl:template name="IPSinfo">
        <xsl:param name="type"/>
        <xsl:param name="title"/>
        <xsl:param name="date"/>
        
        <xsl:variable name="typedisplay">
            <xsl:choose>
                <xsl:when test="$type/fhir:text">
                    <xsl:value-of select="$type/fhir:text/@value"/>
                </xsl:when>
                <xsl:when test="$type/fhir:coding/fhir:display">
                    <xsl:value-of select="$type/fhir:coding/fhir:display/@value"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$title"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
                
        <!-- return a table with HDR data incl the hospital -->
        <table class="meta__header">
            <tr>
                <th colspan="2">
                    <xsl:value-of select="$typedisplay"/>
                </th>
            </tr>
            <xsl:if test="$title != $typedisplay">
                <td colspan="2">
                    <xsl:value-of select="$title"/>
                </td>
            </xsl:if>
            <tr>
                <td>Report Date:</td>
                <td>
                    <strong>
                        <xsl:call-template name="format-date">
                            <xsl:with-param name="date" select="$date"/>
                        </xsl:call-template>
                    </strong>
                </td>
            </tr>
        </table>
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
    
    <xsl:template name="doDislaimer">
        <div class="disclaimer">
            Disclaimer: These web pages are not intended to be used as a source of information on patient care.
            <div>The laboratory reports are clinically reasonable, but synthetic and contain AI generated content.</div>
        </div>
    </xsl:template>
    
    <xsl:template name="back2index">
        <xsl:if test="string-length($JSONsource) > 0">
            <div id="popupDialog">
                <textarea rows="32" cols="70" id="jsonsource"/>
                <a href="#" onclick="togglePopup();" class="mt-11 button">Close</a>
            </div>
        </xsl:if>
        <div>
            <xsl:if test="string-length($JSONsource) > 0">
                <a href="#" onclick="togglePopup();" class="button">Show source</a>
            </xsl:if>
            <div >
                <a href="{$self}" class="button">Home</a>
                <xsl:if test="string-length($selfindex)>0">
                    <a href="{$selfindex}" class="button">
                        Back to focus index
                        <strong><xsl:value-of select="$focusname"/></strong>
                    </a>
                </xsl:if>
            </div>
        </div>
    </xsl:template>
    
</xsl:stylesheet>