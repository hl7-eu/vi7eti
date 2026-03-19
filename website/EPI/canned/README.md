# Stylesheets
**The material provided in this "canned" directory is for testing and example pruposes only.**

## Concept

The stylesheets are part of the [vi7eti](https://vi7eti.net) project. vi7eti – contributed by [HL7 Europe](https://vi7eti.net/hl7europe.org) – is a **reference implementation** of the **vi7eti stylesheets** that come out of the [xShare](https://xshare-project.eu/) and [Gravitate Health](https://www.gravitatehealth.eu/) projects, that shows and demonstrates Visualization of Example and Test Instances based on HL7 CDA or HL7 FHIR specifications (implementation guides).

## Canned directory

This directory contains the original stylesheets that are used to render the example instances.

It uses the XSLT-Standard (Extensible Stylesheet Language Transformation) to transform XML example instances into HTML. In addition CSS (Cascading Style Sheets) and Javascript (JS) is used to create the desired layout and functionality.

The root transformation XSLT stylesheet `wrapper.xsl` acts as a wrapping script that provides the core HTML elements such as `<html>` and `<body>` (that are provided differently for the vi7eti website). It includes the primary core XSLT `primary-core.xsl` that provides all logic for the transformation and that is also indentical to the ones used by the vi7eti website.

Several Cascading Style Sheets and base Javascript functions are also included in the wrapping script. Then the main functions are called from the primary core XSLT to process the example instance.

```
Canned directory XML processing content
|
+ wrapper.xsl

Content from the vi7eti tool
|
+ primary-core.xsl
|
+ styles.css
+ stylemain.css
+ focus-styles.css
|
+ main.js
```



## Rendering Examples

In order to render an example the XML instance must be processed by applying the wrapper.xsl. For some XML frameworks / tools this can be done by mentioning the wrapper xsl as instructions in the top part of the example XML instance.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="wrapper.xsl"?>
<Bundle xmlns="http://hl7.org/fhir">
  <id value="bundlepackageleaflet-en-04c9bd6fb89d38b2d83eced2460c4dc1"/>
  ...
```

This might differ from other tools or frameworks.
