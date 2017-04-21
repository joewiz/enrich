xquery version "3.0";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "import-utilities.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "date-parser.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
 
declare option output:method "html5";
declare option output:media-type "text/html";

declare function local:wrap-html($title, $body) {
    <html>
        <head>
            <title>{$title}</title>
            <meta name="viewport" content="width=device-width, initial-scale=1"/>
            <!-- Latest compiled and minified CSS -->
            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css"/>
            
            <!-- Optional theme -->
            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap-theme.min.css"/>
            <link rel="stylesheet" href="quarterly-release-print.css"/>
            <!-- Latest compiled and minified JavaScript -->
            <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"/>
            
        </head>
        <body>
            <div class="container">
                <h1>{$title}</h1>
                {$body}
            </div>
        </body>
    </html>
};

declare function local:form($visits as xs:string*, $action as xs:string) {
    <div class="form-group">
        <form action="02-check-fields.xq" method="post">
            {if ($action = 'valid-tsv') then <input type="hidden" name="valid-tsv" value="true"/> else ()}
            <label for="tsv" class="control-label">TSV</label>
            <div>
                <textarea name="tsv" id="tsv" class="form-control" rows="6">{$visits}</textarea>
            </div>
            <button type="submit" class="btn btn-default">Check Fields</button>
            {if ($action = 'valid-tsv') then () else <a class="btn btn-default" href="{request:get-url()}" role="button">Clear</a>}
        </form>
    </div>
};

let $title := 'TSV Import Helper'
let $new-tsv := request:get-parameter('tsv', ())
let $body :=
    if ($new-tsv) then
        local:form($new-tsv, 'check-fields')
    else
        (
        local:form((), 'check-fields'),
        <p>Please enter tab-separated values. Column headings should be on first line, also tab-separated. One column heading should contain the word "date". Blank or whitespace-only lines will be discarded. (Click <a href="?tsv=January%202-5,%202014%09Israel%09Jerusalem%09Met%20with%20Prime%20Minister%20Benjamin%20Netanyahu%20and%20Foreign%20Minister%20Avigdor%20Lieberman.">here</a> to try.)</p>
        )
return
    local:wrap-html($title, $body)