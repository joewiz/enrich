(: ----------------- :)

xquery version "3.0";

let $start := max(collection('/db/cms/apps/visits/data')//id)
for $trip at $count in doc('/db/cms/apps/visits/data/2010-new.xml')//visit
let $id := update insert <id>{$start + $count}</id> preceding $trip/date
return $trip


(: ----------------- :)

xquery version "3.0";

for $visit at $count in doc('/db/cms/apps/visits/data/2010-new.xml')//visit
let $stamp := 
    (
    <created-by>wicentowskijc</created-by>,
    <created-datetime>{current-dateTime()}</created-datetime>,
    <last-modified-by>wicentowskijc</last-modified-by>,
    <last-modified-datetime>{current-dateTime()}</last-modified-datetime>,
    <release-status-code>released</release-status-code>,
    <released-by>wicentowskijc</released-by>,
    <release-datetime>{current-dateTime()}</release-datetime>,
    <recalled-by/>,
    <recall-datetime/>
    )
let $update := update insert $stamp following $visit/description
return $visit


(: ----------------- :)

xquery version "3.0";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "/db/cms/modules/import-utilities.xqm";

for $visit at $count in doc('/db/cms/apps/visits/data/2010-new.xml')//visit
let $date-check := iu:analyze-date-string($visit/date)
return 
    if ($date-check/self::error) then 
        <problem>{$visit/id, $date-check}</problem> 
    else ()


(: ----------------- :)

xquery version "3.0";

import module namespace iu = "http://history.state.gov/ns/xquery/import-utilities" at "/db/cms/modules/import-utilities.xqm";
import module namespace dates = "http://xqdev.com/dateparser" at "/db/cms/modules/date-parser.xqm";

for $visit at $count in doc('/db/cms/apps/visits/data/2010-new.xml')//visit
let $date := $visit/date
let $dates := iu:analyze-date-string($visit/date)
let $start-date := dates:parseDate($dates/descendant-or-self::date[1])/string()
let $end-date := dates:parseDate($dates/descendant-or-self::date[last()])/string()
let $update := 
    (
    update insert (element start-date {$start-date}, element end-date {$end-date}) following $date
    ,
    update delete $date
    )
return <new>{$start-date} - {$end-date}</new>


(: ----------------- :)

xquery version "3.0";

for $visit at $count in doc('/db/cms/apps/visits/data/2010-new.xml')//visit
let $country := $visit/from
let $countries := collection('/db/cms/apps/countries/data')//country
let $country := 
    if ($country/@id ne '') then () 
    else if ($countries/label = $country/text()) then
        update insert attribute id {$countries[label eq $country/text()]/id/text()} into $visit/from
    else (
        update insert attribute id {''} into $visit/country
        ,
        'fix-me'
        )
return if ($country eq 'fix-me') then $visit else ()