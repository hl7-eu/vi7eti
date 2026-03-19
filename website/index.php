<?php

/**
 * vi7eti Web Interface — index.php
 *
 * vi7eti © dr Kai Heitmann, HL7 Europe | AGPL-3.0 license
 * https://github.com/hl7-eu/vi7eti/
 *
 * Single-entry-point web application that renders FHIR R4.0 example and test
 * instances as human-readable HTML. Input can be a local file (selected from
 * the focus directory listing), an external URL, or a user-uploaded file.
 * Transformation is performed server-side using SAXON via Java exec().
 *
 * ============================================================================
 * DIRECTORY STRUCTURE
 * ============================================================================
 *
 *   bin/                     SAXON XSLT processor JAR + Parsedown Markdown lib
 *   fhir40/                  FHIR R4.0 JSON→XML XSLT stylesheets (ART-DECOR®)
 *     wrapped-fhir-json2xml.xsl  Entry-point wrapper for JSON→XML conversion
 *     fhir-json2xml.xsl          Core JSON→XML transform rules
 *     fhir-xml2json.xsl          (included, not used by vi7eti)
 *   assets/                  Global CSS and JS
 *   <focus>/                 One directory per focus group (e.g. eulab, ips)
 *     *.json / *.xml / *.html    Source FHIR example files
 *     transform/
 *       primary-core.xsl         Focus-specific XSLT (HTML rendition)
 *     assets/css/
 *       focus-styles.css         Focus-specific CSS injected into rendition
 *   img/                     Website images
 *   tmpl/                    HTML templates with %%PLACEHOLDER%% markers
 *     index.html             Outer page shell
 *     main.html              Landing page banner
 *     project.html           Single focus tile (landing grid)
 *     projects.html          Focus tile grid wrapper
 *     focus.html             Single-focus file listing + drag-and-drop
 *     drops.html             Drag-and-drop upload zone
 *     rendeer.html           FHIR rendition viewer page
 *     info.html              Generic Markdown info page
 *     footer.html            Site footer
 *   config.php               $FOCUSCONFIG and $MENU definitions
 *
 * ============================================================================
 * TEMPLATE PLACEHOLDER TOKENS
 * ============================================================================
 *
 *   %%TITLE%%          Page / focus title
 *   %%NAVULLI%%        Navigation <ul><li> block
 *   %%HEADER%%         Page header (set to VI7ETITITLE on all pages)
 *   %%BANNER%%         Optional extra banner (cleared for focus pages)
 *   %%MAIN%%           Secondary content area (JSON source dialog or empty)
 *   %%BODY%%           Primary page content
 *   %%ADDITIONALCSS%%  Focus-specific <link> tag or empty string
 *   %%RENDITION%%      Rendered FHIR HTML or Markdown HTML
 *   %%TEASER%%         Full application teaser string with pronunciation
 *   %%DISCLAIMER%%     Disclaimer text for rendered FHIR instances
 *   %%SHOWSOURCE%%     "Show source" button (eulab JSON only) or empty
 *   %%LISTURL%%        URL for the "Back to list" button
 *   %%LISTBUTTONCLASS%% CSS class to show/hide the "Back to list" button
 *   %%FOOTER%%         Footer block
 *   %%CLFOCUS%%        Focus directory name (drag-and-drop zone)
 *   %%SELFSCRIPT%%     Self-referencing script name (index.php)
 *   %%FOCUSLOGO%%      MDI icon class + colour for focus tile
 *   %%DIR%%            Focus directory name (project tile)
 *   %%DESC%%           Focus description (project tile)
 *   %%PROJECTLIST%%    All focus project tiles combined
 *
 * ============================================================================
 * URL PARAMETER ROUTING
 * ============================================================================
 *
 *   ?json=<focus>/<file>           Render a local FHIR JSON file
 *   ?json=<focus>&url=<http://...> Fetch + render a remote FHIR JSON file
 *   ?xml=<focus>/<file>            Render a local FHIR XML file
 *   ?xml=<focus>&url=<http://...>  Fetch + render a remote FHIR XML file
 *   ?html=<focus>/<file>           Display a pre-rendered HTML file as-is
 *   ?download=<focus>/<file>       Serve a file as a browser download
 *   ?focus=<focus>                 Show the file listing for one focus group
 *   ?menu=<key>                    Navigate to a declared menu page
 *   POST + multipart upload        Process an uploaded JSON or XML file
 *
 * ============================================================================
 * TRANSFORMATION PIPELINE
 * ============================================================================
 *
 * JSON input:
 *   1. SAXON: wrapped-fhir-json2xml.xsl → FHIR XML (in /tmp)
 *   2. SAXON: <focus>/transform/primary-core.xsl → HTML rendition
 *
 * XML input:
 *   1. SAXON: <focus>/transform/primary-core.xsl → HTML rendition
 *
 * HTML input:
 *   1. File content returned directly (no transformation)
 *
 * ============================================================================
 * CONSTANTS
 * ============================================================================
 *
 *   VI7ETINAME          "vi7eti"
 *   VI7ETIVERSION       "..."
 *   VI7ETITITLE         Full application title
 *   VI7ETITEASER        Teaser with IPA pronunciation
 *   VI7ETICONTACT       Contact e-mail (obfuscated in output)
 *   TMPDIR              Temporary file directory ("/tmp")
 *   TMPVI7ETI           Temp file prefix ("____vi7eti.")
 *   FOCUSTRANSFORMCORE  Relative path to focus primary XSLT
 *   FHIR40JSON2XML      Relative path to JSON→XML wrapper XSLT
 *   FATAL / WARNING / ERROR  handleError() severity levels
 *   INERROR             Reserved error-state flag
 *
 * ============================================================================
 * GLOBAL VARIABLES
 * ============================================================================
 *
 *   $SELFSCRIPT        "index.php" — used in self-referencing URLs
 *   $JAVACMD           Java invocation with memory limit (-Xmx4096m)
 *   $JAVAJAR           Path to SAXON HE JAR
 *   $FOCUSCONFIG       Array of focus definitions from config.php
 *   $MENU              Array of menu entries from config.php
 *   $FOCUS             Active subset of $FOCUSCONFIG for this request
 *   $CURRENTMENU       The menu entry matching the current request
 *   $focusrendition    HTML string produced by processURL()
 *   $focussource       Raw source file content (for "Show source" dialog)
 *   $focusdisclaimer   Disclaimer text for the active focus group
 *   $accordiononfocus  Count of active $FOCUS entries
 *   $parsedown         Parsedown instance for Markdown rendering
 *
 * ============================================================================
 * FUNCTION INDEX
 * ============================================================================
 *
 *   processURL()         Transform a FHIR file and return HTML rendition
 *   validInputFile()     Validate an uploaded/fetched file by extension
 *   handleError()        Display an error message and optionally halt
 *   antispambot()        Obfuscate an e-mail address
 *   zeroise()            Zero-pad a number to a minimum width
 *   pretty_json()        Re-encode a value as 2-space-indented JSON
 *   markup_json()        Colour-code JSON tokens with HTML <span> elements
 *   test_pretty_json_object()  PHPUnit test for pretty_json() with object
 *   test_pretty_json_str()     PHPUnit test for pretty_json() with scalar
 *   test_markup_json()         PHPUnit test for markup_json()
 *
 */

// ============================================================================
// PHP RUNTIME CONFIGURATION
// ============================================================================

/** Allow up to 2 GB RAM — needed for large FHIR Bundle processing. */
ini_set('memory_limit', '2048M');

/**
 * Disable PCRE JIT compiler.
 * Prevents crashes on some hosts when markup_json() applies complex regexes
 * against large JSON strings.
 */
ini_set("pcre.jit", "0");


// ============================================================================
// APPLICATION IDENTITY CONSTANTS
// ============================================================================

define("VI7ETINAME",    "vi7eti");
define("VI7ETIVERSION", "1.9");
define("VI7ETITITLE",   "Visualize HL7 Example and Test Instances (vi7eti)");
define("VI7ETITEASER",  "Visualize HL7 Example and Test Instances (vi7eti), pronounced /viːˈsɛtiː/");
define("VI7ETICONTACT", "kai.heitmann@hl7europe.org");


// ============================================================================
// MARKDOWN SUPPORT
// ============================================================================

include('bin/Parsedown.php');
$parsedown = new Parsedown();


// ============================================================================
// TEMP FILE CONSTANTS
// ============================================================================

/** Directory for intermediate transformation files. */
define("TMPDIR",    "/tmp");

/** Prefix for all vi7eti-owned temp files — aids manual cleanup. */
define("TMPVI7ETI", "____vi7eti.");


// ============================================================================
// SEVERITY CONSTANTS  (used by handleError())
// ============================================================================

define("FATAL",   -1);
define("WARNING",  1);
define("ERROR",    2);

/** Reserved internal error-state flag. */
define("INERROR", TRUE);


// ============================================================================
// TRANSFORMATION PATH CONSTANTS
// ============================================================================

/** Relative path (inside a focus directory) to the primary rendering XSLT. */
define("FOCUSTRANSFORMCORE", "/transform/primary-core.xsl");

/**
 * FHIR R4.0 JSON → XML XSLT entry point (ART-DECOR®).
 * The wrapper stylesheet accepts a JSON file path as a parameter and
 * delegates to fhir-json2xml.xsl for the actual conversion rules.
 */
define("FHIR40JSON2XML", "fhir40/wrapped-fhir-json2xml.xsl");


// ============================================================================
// RUNTIME VARIABLES
// ============================================================================

/** Self-referencing script name used in all internally generated URLs. */
$SELFSCRIPT = "index.php";

/**
 * Java invocation command with a 4 GB heap limit.
 * SAXON requires sufficient heap for large FHIR Bundle transformations.
 */
$JAVACMD = "java -Xmx4096m -jar";

/** Path to the SAXON HE JAR file. */
$JAVAJAR = "bin/saxon-he-11.5.jar";


// ============================================================================
// CONFIGURATION LOADING
// ============================================================================

require "config.php";

if (!isset($FOCUSCONFIG)) {
    handleError(FATAL, "+++ config file does not contain proper focus definitions (FOCUSCONFIG)");
}
if (!isset($MENU)) {
    handleError(FATAL, "+++ config file does not contain proper app menu definitions (MENU)");
}

$FOCUS       = $FOCUSCONFIG;  // default: all defined focus groups are active
$CURRENTMENU = $MENU[0];      // default: landing (index) page

$focusrendition  = "";  // HTML rendition produced by processURL()
$focussource     = "";  // raw source file content for the "Show source" dialog
$focusdisclaimer = "";  // disclaimer text for the active focus group


// ============================================================================
// REQUEST ROUTING
// Determine how to handle this request based on which GET/POST parameter
// is present. Priority order (first match wins):
//   1. File upload (POST + $_FILES)
//   2. ?html=
//   3. ?xml=
//   4. ?json=
//   5. ?focus=
//   6. ?download=
//   7. ?menu= (or no parameter → landing page)
// ============================================================================


// ============================================================================
// ROUTE 1 — FILE UPLOAD  (POST multipart/form-data)
// Accepts a single JSON or XML file, validates it, processes it via
// processURL(), and stores the rendition for page assembly.
// ============================================================================
if (isset($_FILES) and isset($_POST['focus'])) {
    if (count($_FILES) > 0) {
        $_GET['focus'] = $_POST['focus'];
    }
    if (isset($_FILES['files']['tmp_name'][0])) {
        foreach ($_FILES as $file) {
            if (strlen($file['tmp_name'][0]) > 0) {
                $origfilename = $file['name'][0];
                $ext          = pathinfo($origfilename, PATHINFO_EXTENSION);

                // Move the upload to a vi7eti-prefixed temp file with a unique name
                $tmpfile = TMPDIR . "/" . uniqid(TMPVI7ETI, true) . "." . $ext;
                $bn      = basename($tmpfile, "." . $ext);
                move_uploaded_file($file['tmp_name'][0], $tmpfile);

                // Validate the uploaded file by attempting to parse it
                if (validInputFile($tmpfile, $ext)) {
                    $focusrendition = processURL("tmp+" . $ext, $tmpfile, $bn, $ext, $_POST['focus']);
                    $focussource    = file_get_contents($tmpfile);
                    $CURRENTMENU    = ['menu' => 'upload', 'dir' => $_GET['focus']];
                } else {
                    handleError(WARNING, "+++ The uploaded file ($ext) is not valid.");
                }
            }
        }
    }

// ============================================================================
// ROUTE 2 — ?html=<focus>/<file>
// Serves a pre-rendered HTML file directly without any transformation.
// The first path component is validated against $FOCUSCONFIG['dir'] entries.
// ============================================================================
} elseif (isset($_GET['html']) > 0) {
    $f = htmlspecialchars($_GET['html'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $d = explode('/', $f)[0];  // first path component = expected focus directory
    if (array_search($d, array_column($FOCUSCONFIG, 'dir')) !== FALSE) {
        if (!preg_match('/^https?:\/\//i', $_GET['html'])) {
            handleError(FATAL, "Only http(s) URLs are accepted."); 
        }
        // resolve and contain before any file access
        $safePath = safeResolvePath($f, $d);
        if ($safePath === FALSE) {
            handleError(FATAL, "Invalid file path.");
        }
        $ext            = pathinfo($f, PATHINFO_EXTENSION);
        $bn             = basename($f, "." . $ext);
        $focusrendition = processURL('html', $f, $bn, $ext, $d);
        $focussource    = safeFetchURL($f);
        if ($focussource === FALSE) {
            handleError(FATAL, "+++ The url could not be fetched or is not permitted.");
        }
        $CURRENTMENU    = ['menu' => 'html', 'dir' => $d];
        $disclaimerix   = array_search($d, array_column($FOCUSCONFIG, 'dir'));
        if ($disclaimerix !== FALSE) $focusdisclaimer = ($FOCUSCONFIG[$disclaimerix]['disclaimer']);
    } else {
        handleError(ERROR, "+++ Error in request.");
    }

// ============================================================================
// ROUTE 3 — ?xml=<focus>/<file>  or  ?xml=<focus>&url=<remote>
// Two sub-modes:
//   a. Local file: transform <focus>/<file>.xml via primary-core.xsl
//   b. Remote URL (?url= present): fetch remote file into /tmp, then transform
// ============================================================================
} elseif (isset($_GET['xml']) > 0) {
    $f = htmlspecialchars($_GET['xml'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $d = explode('/', $f)[0];
    if (array_search($d, array_column($FOCUSCONFIG, 'dir')) !== FALSE) {
        if (isset($_GET['url'])) {
            if (!preg_match('/^https?:\/\//i', $_GET['url'])) {
                handleError(FATAL, "Only http(s) URLs are accepted."); 
            }
            $f       = $_GET['url'];
            $safePath = safeResolvePath($f, $d);
            if ($safePath === FALSE) {
                handleError(FATAL, "Invalid file path.");
            }
            $ext     = pathinfo($f, PATHINFO_EXTENSION);
            $tmpfile = TMPDIR . "/" . uniqid(TMPVI7ETI, true) . "." . $ext;
            $bn      = basename($tmpfile, "." . $ext);
            $forcont = safeFetchURL($f);
            if ($forcont === FALSE) {
                handleError(FATAL, "+++ The url could not be fetched or is not permitted.");
            }
            file_put_contents($tmpfile, $forcont);
            if (validInputFile($tmpfile, $ext)) {
                $focusrendition = processURL("tmp+" . $ext, $tmpfile, $bn, $ext, $d);
                $focussource    = safeFetchURL($tmpfile);
                if ($focussource === FALSE) {
                    handleError(FATAL, "+++ The url could not be fetched or is not permitted.");
                }
                $CURRENTMENU    = ['menu' => 'url', 'dir' => $d];
            } else {
                handleError(WARNING, "+++ The url ($f) is not reachable or content is invalid.");
            }
        } else {
            // Sub-mode a: local file
            $ext            = pathinfo($f, PATHINFO_EXTENSION);
            $bn             = basename($f, "." . $ext);
            $focusrendition = processURL('xml', $f, $bn, $ext, $d);
            $focussource    = file_get_contents($f);
            $CURRENTMENU    = ['menu' => 'xml', 'dir' => $d];
        }
        $disclaimerix = array_search($d, array_column($FOCUSCONFIG, 'dir'));
        if ($disclaimerix !== FALSE) $focusdisclaimer = ($FOCUSCONFIG[$disclaimerix]['disclaimer']);
    } else {
        // echo "+++ error " . var_dump($d) . var_dump(array_search($d, array_column($FOCUSCONFIG, 'dir')) !== FALSE) . $_GET['xml'];
        // echo "+++ error in request";
        handleError(ERROR, "+++ Error in request.");
    }

// ============================================================================
// ROUTE 4 — ?json=<focus>/<file>  or  ?json=<focus>&url=<remote>
// Identical structure to ROUTE 3 but for FHIR JSON input. The JSON is first
// converted to XML by SAXON (wrapped-fhir-json2xml.xsl) and then rendered.
//
// ============================================================================
} elseif (isset($_GET['json']) > 0) {
    $f = htmlspecialchars($_GET['json'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $d = explode('/', $f)[0];
    if (array_search($d, array_column($FOCUSCONFIG, 'dir')) !== FALSE) {
        if (isset($_GET['url'])) {
            if (!preg_match('/^https?:\/\//i', $_GET['url'])) {
                handleError(FATAL, "Only http(s) URLs are accepted."); 
            }
            $f       = $_GET['url'];
            $ext     = pathinfo($f, PATHINFO_EXTENSION);
            $tmpfile = TMPDIR . "/" . uniqid(TMPVI7ETI, true) . "." . $ext;
            $bn      = basename($tmpfile, "." . $ext);
            $forcont = safeFetchURL($f);
            if ($forcont === FALSE) {
                handleError(FATAL, "+++ The url could not be fetched or is not permitted.");
            }
            file_put_contents($tmpfile, $forcont);
            if (validInputFile($tmpfile, $ext)) {
                $focusrendition = processURL("tmp+" . $ext, $tmpfile, $bn, $ext, $d);
                $focussource    = safeFetchURL($tmpfile);
                if ($focussource === FALSE) {
                    handleError(FATAL, "+++ The url could not be fetched or is not permitted.");
                }
                $CURRENTMENU    = ['menu' => 'url', 'dir' => $d];
            } else {
                handleError(WARNING, "+++ The url ($f) is not reachable or content is invalid.");
            }
        } else {
            // Sub-mode a: local file
            $ext            = pathinfo($f, PATHINFO_EXTENSION);
            $bn             = basename($f, "." . $ext);
            $focusrendition = processURL('json', $f, $bn, $ext, $d);
            $focussource    = file_get_contents($f);
            $CURRENTMENU    = ['menu' => 'json', 'dir' => $d];
        }
        $disclaimerix = array_search($d, array_column($FOCUSCONFIG, 'dir'));
        if ($disclaimerix !== FALSE) $focusdisclaimer = ($FOCUSCONFIG[$disclaimerix]['disclaimer']);
    } else {
        handleError(ERROR, "+++ Error in request.");
    }

// ============================================================================
// ROUTE 5 — ?focus=<focus>
// Restricts the landing page tile grid to a single focus group, used when
// navigating into a focus directory from the project tiles.
// The focus directory name is validated against $FOCUSCONFIG.
// ============================================================================
} elseif (isset($_GET['focus']) > 0) {
    $f = htmlspecialchars($_GET['focus'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $d = explode('/', $f)[0];
    if (($focid = array_search($d, array_column($FOCUSCONFIG, 'dir'))) !== FALSE) {
        $FOCUS = array($FOCUSCONFIG[$focid]);  // narrow to one focus group
    } else {
        echo "+++ error in request";
    }

// ============================================================================
// ROUTE 6 — ?download=<focus>/<file>
// Serves a file from within a focus directory as a forced browser download.
// The first path component is validated against $FOCUSCONFIG['dir'].
//
// ============================================================================
} elseif (isset($_GET['download']) > 0) {
    $f = htmlspecialchars($_GET['download'], ENT_QUOTES | ENT_HTML5, 'UTF-8');
    $d = explode('/', $f)[0];
    if (($focid = array_search($d, array_column($FOCUSCONFIG, 'dir'))) !== FALSE) {

        // FIX: resolve and contain before any file access
        $safePath = safeResolvePath($f, $d);
        if ($safePath === FALSE) {
            handleError(ERROR, "Invalid download path.");
            exit;
        }

        $fc = file_get_contents($safePath);
        header("Cache-Control: public");
        header("Content-Description: File Transfer");
        header("Content-Disposition: attachment; filename=" . basename($safePath)); // FIX: basename only
        header("Content-Type: " . mime_content_type($safePath));
        header("Content-Transfer-Encoding: application/text");
        echo $fc;
        exit;
    } else {
        handleError(ERROR, "Invalid request.");
        exit;
    }
// ============================================================================
// ROUTE 7 — ?menu=<key>  (or no parameter → landing page)
// Standard menu navigation. $sp is validated against declared $MENU keys only.
// No filesystem access is performed in this route.
// ============================================================================
} else {
    foreach ($MENU as $ix => $m) {
        $tm = $m['menu'];
        $sp = (isset($_GET['menu']) > 0)
            ? htmlspecialchars($_GET['menu'], ENT_QUOTES | ENT_HTML5, 'UTF-8')
            : "";
        if ($sp === $tm) {
            $CURRENTMENU = $MENU[$ix];
        }
    }
}
/* end of request routing */


// ============================================================================
// PAGE ASSEMBLY
// ============================================================================

/**
 * $accordiononfocus controls the page layout:
 *   1  → single-focus view (file listing + drag-and-drop)
 *   >1 → landing page with all focus tiles
 */
$accordiononfocus = count($FOCUS);

$content = file_get_contents("tmpl/index.html");
$content = str_replace("%%TITLE%%", VI7ETITITLE, $content);

// Build the navigation bar
$nav = "<ul class='nav-links' id='navLinks'>";
if ($accordiononfocus === 1) {
    // When only one focus is shown, provide a simple "Home" back-link
    $nav .= "<li><a href='?menu=index'>Home</a></li>";
} else {
    foreach ($MENU as $m) {
        $title = $m['title'];
        $url   = $SELFSCRIPT . "?menu=" . $m['menu'];
        $nav  .= "<li>";
        if ($m['menu'] !== $CURRENTMENU['menu']) {
            $nav .= "<a href=\"$url\">$title</a>";
        } else {
            // Active item: visually disabled
            $nav .= "<a href=\"$url\" style=\"cursor: not-allowed; opacity: 0.5; text-decoration: none;\">$title</a>";
        }
        $nav .= "</li>";
    }
}
$nav .= "</ul>";
$content = str_replace("%%NAVULLI%%", $nav, $content);
$OUT     = str_replace("%%HEADER%%", VI7ETITITLE, $content);


// ============================================================================
// PAGE RENDERING — ROUTE DISPATCH
// ============================================================================

if ($accordiononfocus === 1) {

    // -------------------------------------------------------------------------
    // SINGLE-FOCUS VIEW
    // Renders the file listing table for one focus group plus the drag-and-drop
    // upload zone. For each file in the focus directory, a table row is built
    // with:
    //   - Patient name and report date (extracted from the JSON Bundle)
    //   - A "View" link routing through ?html=, ?xml=, or ?json= as appropriate
    //   - A "Download" link routing through ?download=
    //   - A file-type icon (MDI)
    //
    // Rows are sorted alphabetically before output.
    // -------------------------------------------------------------------------

    $clfocus = $FOCUS[0]['dir'];
    $content = file_get_contents("tmpl/drops.html");
    $content = str_replace("%%CLFOCUS%%",    $clfocus,    $content);
    $content = str_replace("%%SELFSCRIPT%%", $SELFSCRIPT, $content);
    $DROPS   = $content;

    $OUT = str_replace("%%BANNER%%",        "", $OUT);
    $OUT = str_replace("%%ADDITIONALCSS%%", "", $OUT);

    $content = "";
    $render  = "";

    foreach ($FOCUS as $d) {
        $ddir   = $d['dir'];
        $dlogo  = $d['logo'];
        $dtitle = $d['title'];
        $ddesc  = $d['desc'];
        $dcolor = $d['color'];

        // Enumerate all JSON, XML, and HTML files in the focus directory
        $topdir = getcwd();
        chdir($ddir);
        $alljson = glob("*.json");
        $allxml  = glob("*.xml");
        $allhtml = glob("*.html");
        chdir($topdir);

        // Group files by basename so JSON + XML variants of the same example
        // appear on a single row
        $allbasenames = array();
        foreach (array_merge($alljson, $allxml, $allhtml) as $af) {
            $ext = pathinfo($af, PATHINFO_EXTENSION);
            $bn  = basename($af, "." . $ext);
            $allbasenames[$bn][$ext] = ["dir" => "$ddir", "name" => "$af"];
        }

        if (count($allbasenames) > 0) {
            $content .= "<h3 class='mt-11'>List</h3>";
            $content .= "<div class='feature-card focus' data-animate>";
            $content .= "<table style='width: 100%' class=\"vi7etiftab2\">";
            $content .= "<tr><th>Item</th><th width='10%'>View</th><th width='10%'>Download</th><th width='10%'>Type</th></tr>";

            $rowscontent = array();
            foreach ($allbasenames as $abkey => $ab) {
                $row = "<tr>";

                // Select the best available file format for viewing
                // Priority: html > xml > json
                $fitem = "";
                $link  = "";
                $icon  = "";
                if (isset($ab['html'])) {
                    $fitem = $ab['html']['dir'] . "/" . $ab['html']['name'];
                    $link  = $SELFSCRIPT . "?html=" . $fitem;
                    $icon  = "mdi-web";
                } elseif (isset($ab['xml'])) {
                    $fitem = $ab['xml']['dir'] . "/" . $ab['xml']['name'];
                    $link  = $SELFSCRIPT . "?xml=" . $fitem;
                    $icon  = "mdi-xml";
                } elseif (isset($ab['json'])) {
                    $fitem = $ab['json']['dir'] . "/" . $ab['json']['name'];
                    $link  = $SELFSCRIPT . "?json=" . $fitem;
                    $icon  = "mdi-code-json";
                }

                // Filenames containing spaces cannot be reliably used in URLs
                $linkisavalidurl = !(strstr($fitem, " ") !== FALSE);
                $downloadlink    = $SELFSCRIPT . "?download=" . $fitem;

                // Extract patient name, report date, and resource type from JSON
                $patientname      = "";
                $reportdate       = "";
                $compositiontitle = "<td style='text-align: left !important;'>";
                $resourcetype     = "";

                if (is_file("$fitem")) {
                    $pnfc = file_get_contents("$fitem");
                    if ($pnfc !== FALSE) {
                        $jsonData = json_decode($pnfc, FALSE);
                        if ($jsonData !== NULL) {
                            if (isset($jsonData->resourceType))
                                $resourcetype = "(" . $jsonData->resourceType . ")";

                            foreach ($jsonData->entry as $e) {
                                if ($e->resource->resourceType === 'Patient') {
                                    // Patient name resolution with multiple fallbacks
                                    if (isset($e->resource->name[0]->text)) {
                                        $patientname = (string) $e->resource->name[0]->text;
                                    } elseif (isset($e->resource->name[0]->family)) {
                                        $patientname = (string) $e->resource->name[0]->family;
                                        if (isset($e->resource->name[0]->given))
                                            $patientname = join(" ", $e->resource->name[0]->given) . " " . $patientname;
                                        if (isset($e->resource->name[1]->given))
                                            $patientname = join(" ", $e->resource->name[1]->given) . " " . $patientname;
                                    }
                                    if (isset($e->resource->birthDate)) {
                                        $age          = date('Y') - date('Y', strtotime($e->resource->birthDate));
                                        $patientname .= " ($age)";
                                    }
                                }
                                if ($e->resource->resourceType === 'Composition') {
                                    if (isset($e->resource->date))
                                        $reportdate = date('Y-m-d', strtotime($e->resource->date));
                                }
                            }
                            $compositiontitle .= strlen($patientname) > 0 ? $patientname : "File " . $abkey;
                            $compositiontitle .= strlen($reportdate)  > 0 ? " – " . $reportdate : "";
                        } else {
                            $compositiontitle .= "File " . $abkey;
                        }
                    } else {
                        $compositiontitle .= "File " . $abkey;
                    }
                } else {
                    $compositiontitle .= "File " . $abkey;
                }

                $compositiontitle .= $linkisavalidurl
                    ? " </td>"
                    : " <span class='notvalidfile'/>(name not valid)</span></td>";

                // Build the View and Download cells
                if (strlen($link) > 0 and $linkisavalidurl) {
                    $fitem = "$compositiontitle <td><a href='" . $link . "'><i class='mdi mdi-eye'> </i></a>";
                } else {
                    $fitem = "$compositiontitle <td><i class='mdi mdi-eye grayedout'>";
                }
                $fitem .= $linkisavalidurl
                    ? "</td><td><a href='" . $downloadlink . "'><i class='mdi mdi-download'> </i></a></td>"
                    : "</td><td><i class='mdi mdi-download grayedout'> </i></td>";

                $row .= $fitem;
                $row .= "<td> " . (strlen($icon) > 0 ? "<i class='mdi $icon'> </i>" : "") . " </td></tr>";
                $rowscontent[] = $row;
            }

            // Sort rows alphabetically (by patient name / file name prefix)
            sort($rowscontent);
            $content .= implode("\n", $rowscontent);
            $content .= "</table>";
        }

        $render .= <<<SECT
        <div class="feature-card focus" data-animate>
            <i class="mdi $dlogo vi7eti_$dcolor"></i>
            <h3>$dtitle</h3>
            <div>$ddesc</div>
        </div>
        $content
        </div>
SECT;
    }

    $render .= $DROPS;
    $page    = file_get_contents('tmpl/focus.html');
    $content = str_replace("%%RENDITION%%", $render,       $page);
    $content = str_replace("%%TITLE%%",     $dtitle,       $content);
    $OUT     = str_replace("%%MAIN%%",      "",            $OUT);
    $OUT     = str_replace("%%BODY%%",      $content,      $OUT);
    $OUT     = str_replace("%%TEASER%%",    VI7ETITEASER,  $OUT);

} elseif ($CURRENTMENU['menu'] === 'index') {

    // -------------------------------------------------------------------------
    // LANDING PAGE — focus tile grid
    // Renders a card for each focus group defined in $FOCUSCONFIG.
    // Each card shows the focus logo, title, description, and links to
    // ?focus=<dir> to enter that focus group's file listing.
    // -------------------------------------------------------------------------
    $content = file_get_contents('tmpl/main.html');
    $OUT     = str_replace("%%MAIN%%", $content, $OUT);

    $projext1content = file_get_contents('tmpl/project.html');
    $projectlist     = "";
    foreach ($FOCUS as $d) {
        $logoencolor = $d['logo'] . " vi7eti_" . $d['color'];
        $content     = str_replace("%%FOCUSLOGO%%", $logoencolor, $projext1content);
        $content     = str_replace("%%TITLE%%",     $d['title'],  $content);
        $content     = str_replace("%%DIR%%",       $d['dir'],    $content);
        $content     = str_replace("%%DESC%%",      $d['desc'],   $content);
        $projectlist .= $content;
    }
    $content = file_get_contents('tmpl/projects.html');
    $content = str_replace("%%PROJECTLIST%%", $projectlist, $content);
    $OUT     = str_replace("%%BODY%%",        $content,     $OUT);
    $OUT     = str_replace("%%ADDITIONALCSS%%", "",         $OUT);

} elseif (
    $CURRENTMENU['menu'] === 'html' or
    $CURRENTMENU['menu'] === 'xml'  or
    $CURRENTMENU['menu'] === 'json' or
    $CURRENTMENU['menu'] === 'upload' or
    $CURRENTMENU['menu'] === 'url'
) {

    // -------------------------------------------------------------------------
    // FHIR RENDITION PAGE
    // Displays the HTML output produced by processURL(). Includes:
    //   - The focus disclaimer
    //   - "Show source" button (eulab + JSON only) — toggles a raw JSON dialog
    //   - "Back to list" button (hidden for remote URL requests)
    //   - Optional focus-specific CSS injection
    //
    // If there is exactly one accordion section in the rendition, it is opened
    // automatically by adding the "accordion__initially__open" CSS class.
    // -------------------------------------------------------------------------
    $ddir    = $CURRENTMENU['dir'];
    $content = file_get_contents("tmpl/rendeer.html");

    // Auto-open the accordion if there is only one section
    if (substr_count($focusrendition, 'accordion__item') === 1) {
        $focusrendition = str_replace(
            "accordion__item",
            "accordion__item accordion__initially__open",
            $focusrendition
        );
    }

    $content     = str_replace("%%RENDITION%%",  $focusrendition, $content);
    $content     = str_replace("%%TEASER%%",     VI7ETITEASER,    $content);
    $ddisclaimer = "<strong>Disclaimer: FOR TEST AND EXAMPLE PURPOSES ONLY!</strong> " . $focusdisclaimer;
    $content     = str_replace("%%DISCLAIMER%%", $ddisclaimer,    $content);

    // "Show source" button is shown only for eulab JSON renditions
    if ($CURRENTMENU['menu'] === 'json' and $ddir === 'eulab') {
        $showsourcebtn = "<a href='#' onclick='togglePopup();' class='accent-gradient gradient-btn'>Show source</a>";
        $content       = str_replace("%%SHOWSOURCE%%", $showsourcebtn, $content);
    } else {
        $content = str_replace("%%SHOWSOURCE%%", "", $content);
    }

    $OUT = str_replace("%%BODY%%", $content, $OUT);

    // Inject focus-specific CSS if the stylesheet exists
    $focuscss = $ddir . '/assets/css/focus-styles.css';
    $OUT      = str_replace(
        "%%ADDITIONALCSS%%",
        is_file($focuscss) ? "<link rel='stylesheet' href='$focuscss'>" : "",
        $OUT
    );

    // "Back to list" button
    $OUT = str_replace("%%LISTURL%%", $SELFSCRIPT . "?focus=" . $ddir, $OUT);
    $OUT = str_replace(
        "%%LISTBUTTONCLASS%%",
        $CURRENTMENU['menu'] === 'url' ? "nodisplay" : "",
        $OUT
    );

    // JSON source popup dialog (eulab only)
    if ($CURRENTMENU['menu'] === 'json' and $ddir === 'eulab') {
        $jsonpretty  = pretty_json(json_decode($focussource));
        $jsondialog  = "<div id='popupDialog'>";
        $jsondialog .= "<textarea rows='50' cols='140'>$jsonpretty</textarea>";
        $jsondialog .= "<a href='#' onclick='togglePopup();' class='mt-11 btn accent-gradient gradient-btn'>Close</a>";
        $jsondialog .= "</div>";
        $OUT = str_replace("%%MAIN%%", $jsondialog, $OUT);
    } else {
        $OUT = str_replace("%%MAIN%%", "", $OUT);
    }

} else {

    // -------------------------------------------------------------------------
    // GENERIC INFO PAGE
    // Renders any Markdown file declared in $MENU['file'].
    // The Markdown source is stripped up to the first "# " heading before
    // being passed to Parsedown, so front-matter is not displayed.
    // -------------------------------------------------------------------------
    $file    = $CURRENTMENU['file'];
    $content = file_get_contents('tmpl/info.html');
    $content = str_replace("%%TEASER%%", VI7ETITEASER, $content);
    $render  = file_get_contents($file);
    $render  = substr($render, strpos($render, '# '));
    $render  = $parsedown->text($render);
    $content = str_replace("%%RENDITION%%", $render, $content);
    $OUT     = str_replace("%%BODY%%",      $content, $OUT);
    $OUT     = str_replace("%%MAIN%%",      "",       $OUT);
    $OUT     = str_replace("%%ADDITIONALCSS%%", "",   $OUT);
}


// ============================================================================
// FOOTER ASSEMBLY
// ============================================================================

$content = file_get_contents('tmpl/footer.html');
$content = str_replace("%%NAME%%",         VI7ETINAME,                               $content);
$content = str_replace("%%VERSION%%",      VI7ETIVERSION,                            $content);
$content = str_replace("%%CONTACTEMAIL%%", "mailto:" . antispambot(VI7ETICONTACT),   $content);
$content = str_replace("%%CURRENTYEAR%%",  date('Y'),                                $content);
$OUT     = str_replace("%%FOOTER%%",       $content,                                 $OUT);

// ============================================================================
// HTTP SECURITY HEADERS
// Must be sent before any output (echo, template rendering, file_get_contents)
// ============================================================================

/**
 * Prevent the page from being embedded in an iframe on other origins.
 * Mitigates clickjacking attacks.
 * frame-ancestors in the CSP below is the modern equivalent, but this
 * header is retained for compatibility with older browsers.
 */
header("X-Frame-Options: SAMEORIGIN");

/**
 * Prevent browsers from MIME-sniffing responses away from the declared
 * Content-Type. Particularly important here because vi7eti serves both
 * JSON and XML files directly via the ?download= route.
 */
header("X-Content-Type-Options: nosniff");

/**
 * Restrict the Referer header to origin-only on cross-origin requests.
 * Prevents the full URL (which may contain ?json= / ?xml= parameters with
 * internal file paths) from leaking to external sites.
 */
header("Referrer-Policy: strict-origin-when-cross-origin");

/**
 * Content Security Policy.
 *
 * Directive breakdown:
 *
 *   default-src 'self'
 *     Baseline: only load resources from the same origin unless a more
 *     specific directive below overrides it.
 *
 *   style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net
 *     'self'                   — local CSS files (assets/, focus assets/)
 *     'unsafe-inline'          — required because markup_json() emits
 *                                style="color:..." attributes directly in HTML
 *     fonts.googleapis.com     — Google Fonts CSS
 *     cdn.jsdelivr.net         — Material Design Icons CSS
 *
 *   font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net
 *     fonts.gstatic.com        — actual .woff2 files for Google Fonts
 *     cdn.jsdelivr.net         — MDI .woff2 icon font files
 *
 *   script-src 'self' 'unsafe-inline'
 *     'self'                   — assets/js/main.js and focus JS files
 *     'unsafe-inline'          — required for onclick="togglePopup();" and
 *                                any other inline event handlers in templates.
 *                                Replace with a nonce-based approach if the
 *                                templates are refactored to remove inline JS.
 *
 *   img-src 'self' data:
 *     'self'                   — img/ directory (logos, flags etc.)
 *     data:                    — base64 inline images sometimes emitted by
 *                                the XSLT rendition stylesheets
 *
 *   connect-src 'self'
 *     Restricts XHR / fetch() calls to same origin only. vi7eti performs
 *     all remote fetching server-side (safeFetchURL), not from the browser.
 *
 *   frame-ancestors 'none'
 *     Disallows embedding this page in any frame or iframe, including
 *     same-origin ones. More broadly supported than X-Frame-Options in
 *     modern browsers. Adjust to 'self' if you need same-origin framing.
 *
 *   base-uri 'self'
 *     Prevents injection of a <base> tag that could redirect all relative
 *     URLs to an attacker-controlled origin.
 *
 *   form-action 'self'
 *     Restricts where the file upload <form> (POST to index.php) may
 *     submit to. Prevents a injected form from exfiltrating uploaded files.
 *
 * NOTE: If the XSLT rendition output for any focus group loads additional
 * external resources (e.g. a terminology server, external images), those
 * domains must be added to the appropriate directive here.
 */
header(
    "Content-Security-Policy: "
    . "default-src 'self'; "
    . "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net; "
    . "font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net; "
    . "script-src 'self' 'unsafe-inline'; "
    . "img-src 'self' data:; "
    . "connect-src 'self'; "
    . "frame-ancestors 'none'; "
    . "base-uri 'self'; "
    . "form-action 'self';"
);
echo $OUT;
exit;


// ============================================================================
// FUNCTIONS
// ============================================================================


/**
 * Display an error message in the browser and optionally halt execution.
 *
 * @param  int    $severity  FATAL (-1) halts via die(); WARNING and ERROR continue.
 * @param  string $text      Error message. Newlines are replaced with <br/>.
 *
 * @return void  Does not return when $severity === FATAL.
 */
function handleError($severity, $text) {
    $text = str_replace("\n", "<br/>", $text);
    $OUT  = "<div class='severitymessage'>" . $text . "</div></body>";
    echo $OUT;
    if ($severity == FATAL) die;
}


/**
 * Validate a file by attempting to parse it according to its extension.
 *
 * For JSON: attempts json_decode() and checks json_last_error().
 * For XML:  attempts simplexml_load_file() with error suppression.
 * Any other extension returns FALSE.
 *
 * Used both for user uploads (after move_uploaded_file()) and for
 * remotely fetched files (after file_put_contents() to /tmp).
 *
 * @param  string $filename   Absolute path to the file to validate.
 * @param  string $extension  File extension without dot: "json" or "xml".
 *
 * @return bool  TRUE if the file is valid and parseable, FALSE otherwise.
 */
function validInputFile($filename, $extension) {
    if ($extension === "json") {
        json_decode(file_get_contents($filename));
        return json_last_error() === JSON_ERROR_NONE;
    } elseif ($extension === 'xml') {
        $xml = @simplexml_load_file($filename);
        return ($xml) ? TRUE : FALSE;
    }
    return FALSE;
}


/**
 * Transform a FHIR file and return the resulting HTML rendition string.
 *
 * Orchestrates a two-step SAXON-based transformation pipeline:
 *
 *   Step 1 (JSON input only):
 *     SAXON + fhir40/wrapped-fhir-json2xml.xsl
 *     Converts FHIR JSON to FHIR XML in memory (output written to a temp file
 *     if needed for the next step).
 *
 *   Step 2 (all types):
 *     SAXON + <focus>/transform/primary-core.xsl
 *     Transforms FHIR XML to the HTML rendition displayed in the browser.
 *     Passes focus-specific CSS and global JS paths as stylesheet parameters.
 *
 *   HTML-only shortcut:
 *     If $formattype is 'html', the file is returned as-is without any SAXON
 *     invocation.
 *
 * The $formattype parameter controls the pipeline path:
 *   'json'     — local JSON file → Step 1 → Step 2
 *   'tmp+json' — uploaded/fetched JSON temp file → Step 1 → Step 2
 *   'xml'      — local XML file → Step 2 only
 *   'tmp+xml'  — uploaded/fetched XML temp file → Step 2 only
 *   'html'     — local HTML file → returned directly
 *
 *
 * @param  string $formattype  One of: 'json', 'tmp+json', 'xml', 'tmp+xml', 'html'.
 * @param  string $f           File path (absolute for tmp+* types, relative otherwise).
 * @param  string $bn          Basename of the file without extension.
 * @param  string $ext         File extension without dot (e.g. "json", "xml").
 * @param  string $dir         Focus directory name (e.g. "eulab", "ips").
 *
 * @return string  HTML rendition string, or an empty string if transformation fails.
 */
function processURL($formattype, $f, $bn, $ext, $dir) {

    global $SELFSCRIPT;
    global $JAVACMD;
    global $JAVAJAR;

    // FIX: two separate uniqid() calls — no aliasing
    $tmpfile = TMPDIR . "/" . uniqid(TMPVI7ETI,          true);
    $errfile = TMPDIR . "/" . uniqid(TMPVI7ETI . "err.", true);

    // Determine whether a JSON source file exists for the "Show source" button
    $sourceJSON = is_file("$dir/$bn.json") ? "$dir/$bn.json" : "";

    // -------------------------------------------------------------------------
    // Step 1 — JSON → XML (FHIR R4.0, via ART-DECOR® XSLT)
    // -------------------------------------------------------------------------
    if ($formattype === 'json' or $formattype === 'tmp+json') {
        $stylesheet = FHIR40JSON2XML;
        $infile     = $formattype === 'tmp+json' ? $f : "../$f";

        // FIX: every variable wrapped in escapeshellarg()
        $command = "$JAVACMD " . escapeshellarg($JAVAJAR)
                 . " -u"
                 . " -xsl:" . escapeshellarg($stylesheet)
                 . " -it JSONfile=" . escapeshellarg($infile)
                 . " 2>> " . escapeshellarg($errfile);

        $OUT = "";
        $ol  = [];
        $rv  = 0;
        exec($command, $ol, $rv);

        if ($rv !== 0) {
            handleError(ERROR, "A (json) error occurred. " . htmlspecialchars(file_get_contents($errfile)));
        }
        $OUT = implode("\n", array_values($ol));
    }

    // -------------------------------------------------------------------------
    // Step 2 — XML → HTML (focus-specific primary-core XSLT)
    // All paths (json, tmp+json, xml, tmp+xml) pass through here.
    // -------------------------------------------------------------------------
    if ($formattype === 'xml'  or $formattype === 'tmp+xml'
     or $formattype === 'json' or $formattype === 'tmp+json') {

        $stylesheet = "$dir" . FOCUSTRANSFORMCORE;

        if ($formattype === 'xml') {
            $infile = "$dir/$bn.$ext";
        } elseif ($formattype === 'tmp+xml') {
            $infile = "/tmp/$bn.$ext";
        } else {
            file_put_contents($tmpfile, $OUT);
            $infile = $tmpfile;
        }

        $addcss = "$dir/assets/css/focus-styles.css";
        $addjs  = "assets/js/main.js";

        // FIX: every variable wrapped in escapeshellarg()
        $command = "$JAVACMD " . escapeshellarg($JAVAJAR)
                 . " -u"
                 . " -xsl:" . escapeshellarg($stylesheet)
                 . " -s:"   . escapeshellarg($infile)
                 . " additionalCSS=" . escapeshellarg($addcss)
                 . " additionalJS="  . escapeshellarg($addjs)
                 . " JSONsource="    . escapeshellarg($sourceJSON)
                 . " 2>> "          . escapeshellarg($errfile);

        $OUT = "";
        $ol  = [];
        $rv  = 0;
        exec($command, $ol, $rv);

        if ($rv !== 0) {
            handleError(ERROR, "An (xml) error occurred. " . htmlspecialchars(file_get_contents($errfile)));
        }
        $OUT = implode("\n", array_values($ol));

        // FIX: clean up temp files after use
        if ($formattype === 'tmp+json' or $formattype === 'tmp+xml') unlink($infile);
        if ($formattype === 'json') unlink($tmpfile);
    }

    // -------------------------------------------------------------------------
    // Final step — return the rendition
    // -------------------------------------------------------------------------
    if ($formattype === 'html' or $formattype === 'xml'  or $formattype === 'tmp+xml'
                               or $formattype === 'json' or $formattype === 'tmp+json') {
        // Clean up error log regardless of outcome
        if (is_file($errfile)) unlink($errfile);
        return $formattype === 'html' ? file_get_contents($f) : $OUT . "\n";
    }
}


/**
 * Fetch a remote URL safely, blocking SSRF attack vectors.
 *
 * Enforces:
 *   - Only http:// or https:// schemes are accepted.
 *   - The hostname must resolve to a public IP — RFC-1918 private ranges
 *     (10.x, 172.16-31.x, 192.168.x), loopback (127.x), link-local
 *     (169.254.x), and IPv6 loopback (::1) are all blocked.
 *   - Maximum response size: 10 MB.
 *   - Connection and total timeout: 10 seconds each.
 *   - Redirects are followed but the final URL is re-validated.
 *
 * @param  string $url  The URL to fetch.
 *
 * @return string|false  Response body on success, FALSE on any failure.
 */
function safeFetchURL(string $url) {

    // Step 1: scheme whitelist — only http and https
    if (!preg_match('/^https?:\/\//i', $url)) {
        error_log("vi7eti safeFetchURL: rejected non-http(s) scheme: $url");
        return FALSE;
    }

    // Step 2: parse and resolve the hostname before making any connection
    $host = parse_url($url, PHP_URL_HOST);
    if (empty($host)) {
        error_log("vi7eti safeFetchURL: could not parse host from: $url");
        return FALSE;
    }

    // Strip IPv6 brackets if present (e.g. [::1] → ::1)
    $host = trim($host, '[]');

    // Resolve the hostname to an IP address
    $ip = gethostbyname($host);
    if ($ip === $host && !filter_var($ip, FILTER_VALIDATE_IP)) {
        // gethostbyname() returns the input unchanged when resolution fails
        error_log("vi7eti safeFetchURL: DNS resolution failed for: $host");
        return FALSE;
    }

    // Step 3: block private, loopback, and link-local IP ranges
    $blockedRanges = [
        '/^127\./i',                 // IPv4 loopback
        '/^10\./i',                  // RFC-1918 class A
        '/^172\.(1[6-9]|2\d|3[01])\./', // RFC-1918 class B
        '/^192\.168\./i',            // RFC-1918 class C
        '/^169\.254\./i',            // link-local
        '/^::1$/i',                  // IPv6 loopback
        '/^fc00:/i',                 // IPv6 unique local
        '/^fe80:/i',                 // IPv6 link-local
    ];
    foreach ($blockedRanges as $pattern) {
        if (preg_match($pattern, $ip)) {
            error_log("vi7eti safeFetchURL: blocked private/loopback IP $ip for host $host");
            return FALSE;
        }
    }

    // Step 4: fetch with cURL — restricted protocols, size cap, timeouts
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => TRUE,
        CURLOPT_FOLLOWLOCATION => TRUE,
        CURLOPT_MAXREDIRS      => 3,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT        => 10,
        CURLOPT_PROTOCOLS      => CURLPROTO_HTTP | CURLPROTO_HTTPS,
        CURLOPT_REDIR_PROTOCOLS => CURLPROTO_HTTP | CURLPROTO_HTTPS,
        CURLOPT_MAXFILESIZE    => 10 * 1024 * 1024,  // 10 MB cap
        CURLOPT_USERAGENT      => 'vi7eti/1.6',
    ]);

    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $err  = curl_error($ch);
    curl_close($ch);

    if ($body === FALSE || $code !== 200) {
        error_log("vi7eti safeFetchURL: fetch failed for $url (HTTP $code, cURL: $err)");
        return FALSE;
    }

    return $body;
}

/**
 * Obfuscate an e-mail address to hinder spam-harvesting bots.
 * Each character is randomly encoded as a decimal HTML entity, a plain
 * ASCII character, or (when $hex_encoding > 0) a percent-encoded byte.
 * The "@" character is always rendered as &#64;.
 *
 * @param  string $email_address  The e-mail address to obfuscate.
 * @param  int    $hex_encoding   0 = entity + plain only; 1 = also allow %XX.
 *
 * @return string  Obfuscated e-mail string safe for HTML output.
 */
function antispambot($email_address, $hex_encoding = 0) {
    $email_no_spam_address = '';
    for ($i = 0, $len = strlen($email_address); $i < $len; $i++) {
        $j = rand(0, 1 + $hex_encoding);  // ⚠️  LOW: use random_int() instead
        if (0 == $j) {
            $email_no_spam_address .= '&#' . ord($email_address[$i]) . ';';
        } elseif (1 == $j) {
            $email_no_spam_address .= $email_address[$i];
        } elseif (2 == $j) {
            $email_no_spam_address .= '%' . zeroise(dechex(ord($email_address[$i])), 2);
        }
    }
    return str_replace('@', '&#64;', $email_no_spam_address);
}


/**
 * Validate that a user-supplied file path resolves to a real file that sits
 * strictly inside an allowed root directory.
 *
 * Resolves symlinks and "../" sequences via realpath() and then verifies
 * containment using a prefix match with a trailing DIRECTORY_SEPARATOR,
 * preventing a directory named "eulab_evil" from matching a root of "eulab".
 *
 * @param  string $userPath    The path as received from the URL parameter
 *                             (already passed through htmlspecialchars()).
 * @param  string $allowedDir  The focus directory name that must be the
 *                             root of the resolved path (e.g. "eulab").
 *
 * @return string|false  The resolved absolute path on success,
 *                       FALSE if the path is invalid, does not exist,
 *                       or escapes the allowed root.
 */
function safeResolvePath(string $userPath, string $allowedDir) {

    // The allowed root must itself exist and resolve cleanly
    $allowedRoot = realpath($allowedDir);
    if ($allowedRoot === FALSE) {
        error_log("vi7eti safeResolvePath: allowed root does not exist: $allowedDir");
        return FALSE;
    }

    // Resolve the full path — returns FALSE for non-existent paths
    $resolved = realpath($userPath);
    if ($resolved === FALSE) {
        error_log("vi7eti safeResolvePath: path does not exist: $userPath");
        return FALSE;
    }

    // Containment check: resolved path must start with allowedRoot + separator
    if (strpos($resolved, $allowedRoot . DIRECTORY_SEPARATOR) !== 0) {
        error_log("vi7eti safeResolvePath: traversal blocked — $userPath resolved to $resolved outside $allowedRoot");
        return FALSE;
    }

    return $resolved;
}

/**
 * Left-pad a value with zeroes to a minimum string length.
 * Used by antispambot() to produce two-character hex escape sequences.
 *
 * @param  int|string $number     Value to pad.
 * @param  int        $threshold  Minimum output width.
 *
 * @return string  Zero-padded string.
 */
function zeroise($number, $threshold) {
    return sprintf('%0' . $threshold . 's', $number);
}


/**
 * Re-encode a value as compact pretty-printed JSON (2-space indentation).
 * PHP's default json_encode() uses 4-space indentation; this function halves
 * it via a post-processing regex. JSON_HEX_APOS escapes single quotes as
 * \u0027, making the output safe for HTML attribute embedding.
 *
 * @param  mixed  $in  Any JSON-serialisable value.
 *
 * @return string  Pretty-printed JSON with 2-space indentation.
 */
function pretty_json($in): string {
    return preg_replace_callback(
        '/^ +/m',
        function (array $matches): string {
            return str_repeat(' ', strlen($matches[0]) / 2);
        },
        json_encode($in, JSON_PRETTY_PRINT | JSON_HEX_APOS)
    );
}


/**
 * Wrap JSON tokens in colour-coded HTML <span> elements for browser display.
 *
 * Token colour mapping:
 *   Keys (string followed by ":")   → red
 *   String values                   → green
 *   Numeric values / true / false   → darkorange
 *   null                            → magenta
 *
 * HTML special characters are escaped before the colour pass to prevent
 * injection. Returns the original (escaped) input if the regex fails.
 *
 * Usage: echo markup_json(pretty_json(json_decode($rawJson)));
 *
 * @param  string $in  Raw JSON string (not yet HTML-escaped).
 *
 * @return string  HTML string with colour <span> wrappers.
 */
function markup_json(string $in): string {
    $string  = 'green';
    $number  = 'darkorange';
    $null    = 'magenta';
    $key     = 'red';
    $pattern = '/("(\\\\u[a-zA-Z0-9]{4}|\\\\[^u]|[^\\\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/';

    return preg_replace_callback(
        $pattern,
        function (array $matches) use ($string, $number, $null, $key): string {
            $match  = $matches[0];
            $colour = $number;
            if (preg_match('/^"/', $match)) {
                $colour = preg_match('/:$/', $match) ? $key : $string;
            } elseif ($match === 'null') {
                $colour = $null;
            }
            return "<span style='color:{$colour}'>{$match}</span>   ";
        },
        str_replace(['<', '>', '&'], ['&lt;', '&gt;', '&amp;'], $in)
    ) ?? $in;
}


// ============================================================================
// UNIT TESTS
// These functions use $this->assertEquals() and must be run inside a PHPUnit
// test class. They cannot be called standalone from this script.
// TODO: move these to a dedicated tests/ directory.
// ============================================================================

/** PHPUnit test: pretty_json() with a stdClass object. */
function test_pretty_json_object() {
    $ob = new \stdClass();
    $ob->test = 'unit-tester';
    $json     = pretty_json($ob);
    $expected = "{\n  \"test\": \"unit-tester\"\n}";
    $this->assertEquals($expected, $json);
}

/** PHPUnit test: pretty_json() with a plain scalar string. */
function test_pretty_json_str() {
    $ob   = 'unit-tester';
    $json = pretty_json($ob);
    $this->assertEquals("\"$ob\"", $json);
}

/** PHPUnit test: markup_json() chained with pretty_json() and json_decode(). */
function test_markup_json() {
    $json = '[{"name":"abc","id":123,"warnings":[],"errors":null},{"name":"abc"}]';
    $output = markup_json(pretty_json(json_decode($json)));
    // Expected output contains colour-coded <span> elements per token
    $this->assertStringContainsString("<span style='color:red'>", $output);
    $this->assertStringContainsString("<span style='color:green'>", $output);
    $this->assertStringContainsString("<span style='color:darkorange'>", $output);
    $this->assertStringContainsString("<span style='color:magenta'>", $output);
}