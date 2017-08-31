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

declare function local:form($tsv as xs:string*, $status as xs:string*) {
    <div class="form-group">
        <form>
            <label for="tsv" class="control-label">TSV</label>
            <div>
                <textarea name="tsv" id="tsv" class="form-control" rows="6">{$tsv}</textarea>
            </div>
            <button type="submit" class="btn btn-default" formaction="02-check-fields.xq" formmethod="post">Check Rows Again</button>
            <button type="submit" class="btn btn-default" formaction="03-tsv-to-table.xq" formmethod="post">{if ($status='valid') then () else attribute disabled {'disabled'}}View Data as Table</button>
            <a class="btn btn-default" href="{request:get-url()}" role="button">Clear</a>
        </form>
    </div>
};

let $title := 'TSV Import Helper'
let $new-tsv := request:get-parameter('tsv', ())
let $strip-extra-newlines := replace($new-tsv, '\n+', '&#10;')
let $lines := tokenize($strip-extra-newlines, '\n')[not(matches(., '^[\s ]*?$'))]
let $cells-per-row := $lines ! count(tokenize(., '\t'))
let $check-lines := if (count(distinct-values($cells-per-row)) gt 1) then true() else false()
let $body :=
    if ($check-lines) then
        (
        <div class="bg-danger">
            <p>The following rows do not have an identical # of cells. Please check and resubmit.</p>
            <ul>{
                for $line at $n in $lines
                let $cells := $cells-per-row[$n]
                order by $cells
                return
                    <li>{$n} ({$cells} cells): <code>{$line}</code></li>
            }</ul>
        </div>
        ,
        local:form(string-join($lines, '&#10;'), ())
        )
    else
        (
        <div class="bg-success">
            <p>Success! Each row has the expected number of fields.</p>
        </div>
        ,
        local:form(string-join($lines, '&#10;'), 'valid')
        )
return
    local:wrap-html($title, $body)