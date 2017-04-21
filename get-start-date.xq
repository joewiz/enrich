xquery version "3.1";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "/db/apps/tsv-helper/import-utilities.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "/db/apps/tsv-helper/date-parser.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "text";
declare option output:media-type "text/text";

let $date-string := request:get-parameter('date', ())
let $pre-check := iu:analyze-date-string($date-string)
return
    if ($pre-check/self::error) then
        ( 
            response:set-status-code(400)
            ,
            'Error: ' || $pre-check/string()
        ) 
    else 
        let $date := 
            if ($pre-check/self::date) then
                $pre-check/string()
            else (: if ($analyze/self::range) then :)
                $pre-check/date[1]/string()
        return
            try 
                { 
                    dates:parseDate($date)/string() 
                } 
            catch * 
                { 
                    response:set-status-code(400),
                    "Error parsing " || $date-string 
                } 