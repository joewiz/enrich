xquery version "3.1";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "/db/apps/tsv-helper/import-utilities.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "/db/apps/tsv-helper/date-parser.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "text";
declare option output:media-type "text/text";

let $date-string := request:get-parameter('date', ())
let $analyze := iu:analyze-date-string($date-string)
let $start-date :=
    if ($analyze/self::date) then 
        $analyze/string()
    else (: if ($analyze/self--range) then :)
        $analyze/date[2]/string()
(:    else:)
(:        ( :)
(:            response:set-status-code(400):)
(:            ,:)
(:            'Error: ' || $analyze/string():)
(:        ) :)
let $date := try { dates:parseDate($start-date)/string() } catch * { "Error parsing " || $date-string }
return
    $date