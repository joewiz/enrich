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

declare function local:form($tsv as xs:string*, $valid as xs:boolean) {
    <div class="form-group">
        <form>
            <label for="tsv" class="control-label">TSV</label>
            <div>
                <textarea name="tsv" id="tsv" class="form-control" rows="6">{$tsv}</textarea>
            </div>
            <button type="submit" class="btn btn-default" formaction="04-validate-dates.xq" formmethod="post">Check Dates Again</button>
            <button type="submit" class="btn btn-default" formaction="05-parse-dates.xq" formmethod="post">{if ($valid) then () else attribute disabled {"disabled"}}Parse Dates</button>
        </form>
    </div>
};

let $title := 'TSV Import Helper'
let $new-tsv := request:get-parameter('tsv', ())
let $rows := tokenize($new-tsv, '\n')[not(normalize-space(.) = '')]
let $header-row := head($rows)
let $element-names := tokenize($header-row, '\t') ! replace(normalize-space(lower-case(.)), '\s', '-')
let $body-rows := tail($rows)
let $tsv :=
    <csv>{
        for $row in $body-rows
        let $cells := tokenize($row, '\t')
        return
            <record>
                {
                    for $cell at $col in $cells
                    let $element-name := $element-names[$col]
                    return
                        element { $element-name } { normalize-space($cell) }
                }
            </record>
    }</csv>
let $date-problems := 
    for $row at $n in $tsv/record
    let $date-cell := $row/*[name(.) eq 'date']
    let $format-check := iu:analyze-date-string($date-cell)
    let $range-check :=
        if ($format-check/self::error) then 
            <problem line="{$n}" error="{$format-check/string()}">{$date-cell/string()}</problem> 
        else if ($format-check/self::range) then 
            let $start-date := try { dates:parseDate($format-check/date[1])/string() } catch * { <error>Error parsing {$format-check/date[1]/string()}</error> }
            let $end-date := try { dates:parseDate($format-check/date[2])/string() } catch * { <error>Error parsing {$format-check/date[2]/string()}</error> }
            return
                if ($start-date instance of element(error) or $end-date instance of element(error)) then 
                    <problem line="{$n}" error="{
                        string-join(
                            (
                                if ($start-date instance of element(error)) then
                                    $start-date/string()
                                else
                                    "No problem with start-date: " || $start-date
                                ,
                                if ($end-date instance of element(error)) then
                                    $end-date/string()
                                else
                                    "No problem with end-date: " || $end-date
                            ),
                        '; '
                        )
                    }">{$date-cell/string()}</problem>
                else if ($start-date ge $end-date) then 
                    <problem line="{$n}" error="Dates not in chronological order: {$format-check/date[1]} should be on or before {$format-check/date[2]}">{$date-cell/string()}</problem> 
                else
                    ()
        else
            ()
    return
        $range-check
let $body := 
    if (exists($date-problems)) then
        (
        <div class="bg-danger">
            <p>The dates in the following rows have date problems. Please correct the data and select "Check Dates Again":</p>
            <table class="table">
                <thead>
                    <tr>
                        <th>Row</th>
                        <th>Value</th>
                        <th>Error</th>
                    </tr>
                </thead>
                <tbody>{
                    $date-problems ! 
                        <tr>
                            <td>{./@line/string()}</td>
                            <td>{./string()}</td>
                            <td>{./@error/string()}</td>
                        </tr>
                }</tbody>
            </table>
        </div>
        ,
        local:form(string-join($rows, '&#10;'), false())
        )
    else 
        (
        <div class="bg-success">
            <p>Success! Dates pass validity checks.</p>
        </div>
        ,
        local:form(string-join($rows, '&#10;'), true())
        )
return
    local:wrap-html($title, $body)