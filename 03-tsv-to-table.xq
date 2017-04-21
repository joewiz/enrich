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

let $title := 'TSV Import Helper'
let $action := request:get-parameter('action', ())
let $new-tsv := request:get-parameter('tsv', ())
let $rows := tokenize($new-tsv, '\n')
let $header-row := head($rows)
let $body-rows := tail($rows)
let $tsv := 
    <table class="table table-bordered table-striped">
        <tr>
            {
                for $cell in tokenize($header-row, '\t')
                return
                    <th>
                        {
                            if (normalize-space($cell) = '') then 
                                attribute class {"warning"} 
                            else 
                                (),
                            $cell
                        }
                    </th>
            }
        </tr>
        {
        for $row in $body-rows
        let $cells := tokenize($row, '\t')
        return
            <tr>
                {
                    for $cell in $cells
                    return
                        <td>
                            {
                                if (normalize-space($cell) = '') then 
                                    attribute class {"warning"} 
                                else 
                                    (),
                                $cell
                            }
                        </td>
                }
            </tr>
    }</table>
let $body :=
    <div>
        <p>Your input, rendered as a table. Please confirm that all cells are in the expected columns before selecting "Check dates."</p>
        {$tsv}
        <form>
            <input type="hidden" name="tsv" value="{$new-tsv}"/>
            <button type="submit" class="btn btn-default" formaction="01-enter-tsv.xq" formmethod="post">Edit Data</button>
            <button type="submit" class="btn btn-default" formaction="04-validate-dates.xq" formmethod="post">Check Dates</button>
        </form>

    </div>
return
    local:wrap-html($title, $body)