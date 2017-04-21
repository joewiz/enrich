xquery version "3.0";

module namespace iu = "http://history.state.gov/ns/xquery/import-utilities";

(:~
 : Analyzes a date string to make sure that it is in the basic form expected by the date-parser.xqm
 : utility. Splits date ranges into start and end dates, since the date-parser utility
 : only takes one date at a time. 
 : 
 : @param $date-string A space-normalized date string
 : @return Either a date element containing the original date, a range element containing the start and end dates, or an error element
 :)
declare function iu:analyze-date-string($date-string as xs:string) as element() {
    (: regular expressions for each component of a date :)
    let $year-pattern := '(\d{4})'
    let $month-pattern := '(Jan|Feb|Mar|Apr|Jun|Aug|Sep|Sept|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\.?'
    let $day-pattern := '(\d{1,2})'
    let $range-delimiter-pattern := '-' (: dash; not expecting en dash :)

    (: regular expressions to use for matching the different types of expected dates :)
    (: "June 30, 2014" :)
    let $simple-date-pattern := concat('^', $month-pattern, ' ', $day-pattern, ', ', $year-pattern, '$')
    (: "April 3-15, 1943" :)
    let $intra-month-range-pattern := concat('^', $month-pattern, ' ', $day-pattern, $range-delimiter-pattern, $day-pattern, ', ', $year-pattern, '$')
    (: "September 30-October 1, 1973" :)
    let $inter-month-range-pattern := concat('^', $month-pattern, ' ', $day-pattern, $range-delimiter-pattern, $month-pattern, ' ', $day-pattern, ', ', $year-pattern, '$')
    (: "December 7, 1941-August 15, 1945" :)
    let $inter-year-range-pattern := concat('^', $month-pattern, ' ', $day-pattern, ', ', $year-pattern, $range-delimiter-pattern, $month-pattern, ' ', $day-pattern, ', ', $year-pattern, '$')
    
    return
        if (analyze-string($date-string, $simple-date-pattern)//fn:match) then
            let $analysis := analyze-string($date-string, $simple-date-pattern)
            let $groups := $analysis//fn:group
            let $date := substring($groups[1], 1, 3) || ' ' || $groups[2] || ', ' || $groups[3]
            return
                <date>{$date}</date>
        else if (analyze-string($date-string, $intra-month-range-pattern)//fn:match) then
            let $analysis := analyze-string($date-string, $intra-month-range-pattern)
            let $groups := $analysis//fn:group
            let $start-date := substring($groups[1], 1, 3) || ' ' || $groups[2] || ', ' || $groups[4]
            let $end-date := substring($groups[1], 1, 3) || ' ' || $groups[3] || ', ' || $groups[4]
            return
                <range type="intra-month">
                    <date>{$start-date}</date>
                    <date>{$end-date}</date>
                </range>
        else if (analyze-string($date-string, $inter-month-range-pattern)//fn:match) then
            let $analysis := analyze-string($date-string, $inter-month-range-pattern)
            let $groups := $analysis//fn:group
            let $start-date := substring($groups[1], 1, 3) || ' ' || $groups[2] || ', ' || $groups[5]
            let $end-date := substring($groups[3], 1, 3) || ' ' || $groups[4] || ', ' || $groups[5]
            return
                <range type="inter-month">
                    <date>{$start-date}</date>
                    <date>{$end-date}</date>
                </range>
        else if (analyze-string($date-string, $inter-year-range-pattern)//fn:match) then
            let $analysis := analyze-string($date-string, $inter-year-range-pattern)
            let $groups := $analysis//fn:group
            let $start-date := substring($groups[1], 1, 3) || ' ' || $groups[2] || ', ' || $groups[3]
            let $end-date := substring($groups[4], 1, 3) || ' ' || $groups[5] || ', ' || $groups[6]
            return
                <range type="inter-year">
                    <date>{$start-date}</date>
                    <date>{$end-date}</date>
                </range>
        else 
            <error>Unable to verify validity of date string: {$date-string}</error>
};