<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fhir="http://hl7.org/fhir"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:local="http://vi7eti.net/xsltfunctions"
    exclude-result-prefixes="xs fhir xhtml"
    version="2.0">
    
    <xsl:output method="xhtml" doctype-system="about:legacy-compat"/>
    
    <xsl:include href="primary-core.xsl"/>
    
    <!-- let the fhir:Bundle template here get priority over the primary core definitions -->
    <xsl:template match="fhir:Bundle" priority="1">
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
                <link rel="stylesheet" href="styles.css"> </link>
                <link rel="stylesheet" href="focus-styles.css"> </link>
                <title>
                    <xsl:value-of select="$composition/fhir:title/@value"/>
                </title>
            </head>
            <body style="margin: 4rem;">
                <xsl:call-template name="doDislaimer"/>
                <xsl:apply-templates select="$composition"/>
                <script src="main.js"> </script>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template name="doDislaimer">
        <div xmlns="http://www.w3.org/1999/xhtml" class="disclaimer">
            Disclaimer: These web pages are not intended to be used as a source of information on medicines.
            The web pages are not kept up to date and are for demonstration purposes only.
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines
            or the package leaflet of your medicine.
        </div>
        <div xmlns="http://www.w3.org/1999/xhtml" class="testonly">FOR TEST AND EXAMPLE PURPOSES ONLY!</div>
    </xsl:template>
    
</xsl:stylesheet>