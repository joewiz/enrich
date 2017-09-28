xquery version "3.1";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "import-utilities.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "date-parser.xqm";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "xml";
declare option output:media-type "application/xml";

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
                <result>{$pre-check/string()}</result>
            else (: if ($analyze/self::range) then :)
                <result>{$pre-check/date[1]/string()}</result>
        return
            try 
                { 
                    <result>{dates:parseDate($date)/string()}</result>
                } 
            catch * 
                { 
                    response:set-status-code(400),
                    <result>{"Error parsing " || $date-string }</result>
                } 