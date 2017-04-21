(: ----------------- :)

xquery version "3.0";

for $trip at $count in doc('/db/apps/travels/secretary-travels/kerry-john-forbes-2015.xml')//trip
let $stamp := 
    (
    <created-by>wicentowskijc</created-by>,
    <created-datetime>{current-dateTime()}</created-datetime>,
    <last-modified-by>wicentowskijc</last-modified-by>,
    <last-modified-datetime>{current-dateTime()}</last-modified-datetime>
    )
let $update := update insert element id {()} preceding $trip/start-date
let $update := update insert $stamp following $trip/remarks
let $update := update insert (<role>secretary</role>, <name>John Forbes Kerry</name>) following $trip/id
let $update := update insert (attribute who {'kerry-john-forbes'}, attribute role {'secretary'}) into $trip
return $trip

(: ----------------- :)

xquery version "3.0";

let $start := max((collection('/db/apps/travels/president-travels')//id[. ne ''], collection('/db/apps/travels/secretary-travels')//id[. ne '']))
for $trip at $count in doc('/db/apps/travels/secretary-travels/kerry-john-forbes-2015.xml')//trip
let $id := update value $trip/id with $start + $count
return $trip

(: ----------------- :)

xquery version "3.0";

for $trip in doc('/db/apps/travels/secretary-travels/kerry-john-forbes-2015.xml')//trip
let $country := $trip/country
let $countries := collection('/db/apps/gsh/data/countries-old')//country
let $country := 
    if ($country/@id ne '') then () 
    else if ($countries/label = $country/text()) then
        update insert attribute id {$countries[label eq $country/text()]/id/text()} into $trip/country
    else (
        update insert attribute id {''} into $trip/country
        ,
        'fix-me'
        )
return if ($country eq 'fix-me') then $trip else ()