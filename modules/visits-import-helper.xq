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
        <form action="{request:get-url()}" method="post">
            {if ($action = 'valid-tsv') then <input type="hidden" name="valid-tsv" value="true"/> else ()}
            <label for="visits" class="control-label">Visits</label>
            <div>
                <textarea name="visits" id="visits" class="form-control" rows="6">{$visits}</textarea>
            </div>
            <button type="submit" class="btn btn-default">{if ($action = 'valid-tsv') then 'Continue' else 'Check'}</button>
            {if ($action = 'valid-tsv') then () else <a class="btn btn-default" href="{request:get-url()}" role="button">Clear</a>}
        </form>
    </div>
};

let $title := 'Visits Import Helper'
let $new-visits := request:get-parameter('visits', ())
let $valid-tsv := request:get-parameter('valid-tsv', ())
let $action := request:get-parameter('action', ())
let $body := 
    if ($new-visits) then
        if ($action = 'edit') then 
            local:form($new-visits, 'check')
        else if ($action = 'parse-dates') then 
            let $lines := tokenize($new-visits, '\n')
            let $visits :=
                <visits>{
                    for $line at $n in $lines
                    let $cells := tokenize($line, '\t')
                    return
                        <visit>
                            <n>{$n}</n>
                            <date>{$cells[1]}</date>
                            <country>{$cells[2]}</country>
                            <locale>{$cells[3]}</locale>
                            <remarks>{$cells[4]}</remarks>
                        </visit>
                }</visits>
            let $date-problems := 
                for $visit in $visits/visit
                let $date-check := iu:analyze-date-string($visit/date)
                return
                    if ($date-check/self::error) then 
                        <problem line="{$visit/n}">{$visit/date/string()}</problem> 
                    else 
                        ()
            return 
                if (exists($date-problems)) then
                    (
                    <div>
                        <p>Date problems found:</p>
                        <ul>{
                            $date-problems ! <li>{./@line/string()}: {./string}</li>
                        }</ul>
                    </div>
                    ,
                    local:form(string-join($lines, '&#10;'), 'check')
                    )
                else 
                    (
                    <div class="bg-success">
                        <p>Success! Dates all pass validity checks.</p>
                    </div>
                    ,
                    local:form(string-join($lines, '&#10;'), 'parse-dates')
                    )
        else if ($action = 'process-dates') then 
            let $lines := tokenize($new-visits, '\n')[normalize-space(.) ne '']
            let $visits :=
                <visits>{
                    for $line in $lines
                    let $cells := tokenize($line, '\t')
                    let $date := $cells[1]
                    let $dates := iu:analyze-date-string($date)
                    let $start-date := dates:parseDate($dates/descendant-or-self::date[1])/string()
                    let $end-date := dates:parseDate($dates/descendant-or-self::date[last()])/string()
                    return
                        <visit>
                            <source-date>{$date}</source-date>
                            <start-date>{$start-date}</start-date>
                            <end-date>{$end-date}</end-date>
                            <country>{$cells[2]}</country>
                            <locale>{$cells[3]}</locale>
                            <remarks>{$cells[4]}</remarks>
                        </visit>
                }</visits>
            return 
                    (
                    <div class="bg-success">
                        <p>Success! Date columns all converted to date ranges.</p>
                    </div>
                    ,
                    local:form(string-join(for $visit in $visits/visit return string-join($visit/*[position() gt 1]/string(), '&#09;'), '&#10;'), 'parse-dates')
                    )
        else if ($valid-tsv) then
            let $lines := tokenize($new-visits, '\n')
            let $visits := 
                <table class="table table-bordered table-striped">
                    <tr>
                        <th>Date</th>
                        <th>Country</th>
                        <th>Locale</th>
                        <th>Remarks</th>
                    </tr>
                    {
                    for $line in $lines
                    let $cells := tokenize($line, '\t')
                    return
                        <tr>
                            <td>{$cells[1]}</td>
                            <td>{$cells[2]}</td>
                            <td>{$cells[3]}</td>
                            <td>{$cells[4]}</td>
                        </tr>
                }</table>
            return
                <div>
                    <p>Your input, rendered as a table. 
                        <form action="{request:get-url()}?action=edit" method="post">
                            <input type="hidden" name="visits" value="{$new-visits}"/>
                            <button type="submit" class="btn btn-default">Edit data</button>
                            <button type="submit" class="btn btn-default" formaction="{request:get-url()}?action=process-dates">Process Dates</button>
                        </form>
                    </p>
                    {$visits}
                </div>
        else (: check $new-visits input :)
            let $strip-extra-newlines := replace($new-visits, '\n+', '&#10;')
            let $lines := tokenize($strip-extra-newlines, '\n')[not(matches(., '^[\s ]*?$'))]
            let $check-lines := 
                for $line at $n in $lines
                return
                    if (count(tokenize($line, '\t')) = 4) then ()
                    else $n
            return
                if (exists($check-lines)) then
                    (
                    <div class="bg-danger">
                        <p>The following lines do not have the expected # of fields. Please check and resubmit.</p>
                        <ul>{
                            for $line in $check-lines
                            return
                                <li>{$line}: <code>{$lines[$line]}</code></li>
                        }</ul>
                    </div>
                    ,
                    local:form(string-join($lines, '&#10;'), 'check')
                    )
                else
                    (
                    <div class="bg-success">
                        <p>Success! Each row has the expected number of fields.</p>
                    </div>
                    ,
                    local:form(string-join($lines, '&#10;'), 'valid-tsv')
                    )
    else
        (
        local:form((), 'check'),
        <p>Please enter tab-separated visits. (Click <a href="?visits=January%202-5,%202014%09Israel%09Jerusalem%09Met%20with%20Prime%20Minister%20Benjamin%20Netanyahu%20and%20Foreign%20Minister%20Avigdor%20Lieberman.">here</a> to try.)</p>
        )
return
    local:wrap-html($title, $body)