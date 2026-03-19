<?php
/*
    Define the top menu structure
*/
$MENU = [
    [
        "title" => "Home",
        "menu" => "index",
        "file" => ""
    ],
    [
        "title" => "The Story",
        "menu" => "story",
        "file" => "STORY.md"
    ],
    [
        "title" => "Principles",
        "menu" => "principles",
        "file" => "PRINCIPLES.md"
    ],
    [
        "title" => "Topics",
        "menu" => "index#TOPICS",
        "file" => ""
    ],
    [
        "title" => "Examples",
        "menu" => "examples",
        "file" => "EXAMPLES.md"
    ],
    [
        "title" => "Credits+",
        "menu" => "credits",
        "file" => "CCC.md"
    ]
];
/*
    Define the focus topics handled by this instance of vi7eti with
    dir   directory where all xml and json files to be offered for vizualization reside
    title is the text to appear on the tiles and headlines
    color is used for coloring the tiles and renderings
    desc  describes what the foucs topic means
    logo  is the mdi logo to be used on tiles and renderings 
*/
$FOCUSCONFIG = [
    [
        "dir" => "EPI",
        "title" => "Electronic Medicinal Product Information (ePI)",
        "color" => "regular",
        "desc" => "Visualized Example and Test Instances for the Electronic Medicinal Product Information (ePI)
            based on the <a href='https://build.fhir.org/ig/HL7/emedicinal-product-info/'>FHIR Implementation Guide</a>",
        "disclaimer" => "These web pages are not intended to be used as a source of information on medicines.
            The web pages are not kept up to date and are for demonstration purposes only. 
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines or the package leaflet of your medicine.",
        "logo" => "mdi-pill"
    ],
    [
        "dir" => "LAB",
        "title" => "European Laboratory Report",
        "color" => "green",
        "desc" => "Visualized Example and Test Instances for the HL7 Europe Laboratory Report (EU-Lab)
                    based on the 
                    <a href='https://build.fhir.org/ig/hl7-eu/laboratory/'>FHIR Implementation Guide</a>",
        "disclaimer" => "These web pages are not
            intended to be used as a source of information on on healthcare or medicines.
            The web pages are not kept up to date and are for demonstration purposes only. 
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines
            or the package leaflet of your medicine. For up-to-date information on other
            healthcare topics, please consult the relevant reliable sources or an healthcare
            expert, such as a physician etc.",
        "logo" => "mdi-test-tube"
    ],
    [
        "dir" => "IPS",
        "title" => "International Patient Summary (IPS)",
        "color" => "red",
        "desc" => "Visualized Example and Test Instances for the International Patient Summary (IPS)
                    based on the 
                    <a href='https://build.fhir.org/ig/HL7/fhir-ips/'>FHIR Implementation Guide</a>",
        "disclaimer" => "These web pages are not
            intended to be used as a source of information on on healthcare or medicines.
            The web pages are not kept up to date and are for demonstration purposes only. 
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines
            or the package leaflet of your medicine. For up-to-date information on other
            healthcare topics, please consult the relevant reliable sources or an healthcare
            expert, such as a physician etc.",
        "logo" => "mdi-account-heart-outline"
    ],
    [
        "dir" => "HDR",
        "title" => "European Hospital Discharge Letter (HDR)",
        "color" => "yellow",
        "desc" => "Visualized Example and Test Instances for the European Hospital Discharge Letter (HDR)
                    based on the 
                    <!--<a href='https://build.fhir.org/ig/HL7/fhir-ips/'>FHIR Implementation Guide</a>-->",
        "disclaimer" => "These web pages are not
            intended to be used as a source of information on on healthcare or medicines.
            The web pages are not kept up to date and are for demonstration purposes only. 
            For up-to-date information on a medicine, please consult www.ema.europa.eu/medicines
            or the package leaflet of your medicine. For up-to-date information on other
            healthcare topics, please consult the relevant reliable sources or an healthcare
            expert, such as a physician etc.",
        "logo" => "mdi-bed"
    ]
];