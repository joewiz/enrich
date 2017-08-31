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

declare function local:form($tsv as xs:string*, $action as xs:string) {
    <div class="form-group">
        <form action="{request:get-url()}" method="post">
            <label for="tsv" class="control-label">TSV</label>
            <div>
                <textarea name="tsv" id="tsv" class="form-control" rows="6">{$tsv}</textarea>
            </div>
            <button type="submit" class="btn btn-default" formaction="04-validate-dates.xq" formmethod="post">Check Dates Again</button>
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
                    let $is-date := $element-name eq 'date'
                    return
                        if ($is-date) then
                            let $dates := iu:analyze-date-string(normalize-space($cell))
                            let $start-date := try { dates:parseDate($dates/descendant-or-self::date[1])/string() } catch * { "Error parsing " || $dates/descendant-or-self::date[1] }
                            let $end-date := try { dates:parseDate($dates/descendant-or-self::date[last()])/string() } catch * { "Error parsing " || $dates/descendant-or-self::date[last()] }
                            return
                                (
                                    element start-date { $start-date },
                                    element end-date { $end-date }
                                )
                        else
                            element { $element-name } { normalize-space($cell) }
                }
            </record>
    }</csv>
let $table := 
    <table class="table table-bordered table-striped">
        <tr>
            {
                for $head in $tsv/record[1]/*
                return
                    <th>{$head/name()}</th>
            }
        </tr>
        {
        for $row in $tsv/record
        return
            <tr>
                {
                    for $cell in $row/*
                    return
                        if ($cell/self::start-date or $cell/self::end-date) then
                            <td>{ if ($cell castable as xs:date) then format-date($cell, '[MNn] [D], [Y]') else (attribute class { "warning" }, $cell/string()) }</td>
                        else
                            <td>{$cell/string()}</td>
                }
            </tr>
    }</table>
let $filename := 'tsv-' || replace(adjust-dateTime-to-timezone(current-dateTime(), ()), ':', '-') || '.xml'
let $tsv := xmldb:store('/db/apps/tsv-helper', $filename, $tsv)
let $body :=
    <div>
        <p>Date ranges have been split into start and end dates. One day tsv use the same start and end date. The resulting file is stored at {$tsv}.</p>
        {$table}
        <form>
            <input type="hidden" name="tsv" value="{$new-tsv}"/>
            <button type="submit" class="btn btn-default" formaction="01-enter-tsv.xq" formmethod="post">Edit data</button>
            <a class="btn btn-default" href="01-enter-tsv.xq" role="button">Start Over With New Data</a>
            <a class="btn btn-default" href="{$filename}" role="button">Open {$filename}</a>
        </form>
    </div>
return
    local:wrap-html($title, $body)