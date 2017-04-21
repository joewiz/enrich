xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "text";
declare option output:media-type "text/text";

let $country-string := request:get-parameter('country', ())
let $countries := collection('/db/apps/gsh/data/countries-old')//country
let $country-id := 
    if (empty($country-string) or $country-string = '') then 
        () 
    else (: if ($countries/label = $country-string) then :)
        $countries[label eq $country-string]/id/string()
        (:    else:)
(:        ( :)
(:            response:set-status-code(400):)
(:            ,:)
(:            'Error: ' || $analyze/string():)
(:        ) :)
return
    $country-id