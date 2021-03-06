xquery version "3.1";
declare namespace functx = "http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace httpclient="http://exist-db.org/xquery/httpclient";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://www.digital-archiv.at/ns/tei-abstracts/config" at "../modules/config.xqm";
import module namespace app="http://www.digital-archiv.at/ns/tei-abstracts/templates" at "../modules/app.xql";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=json media-type=text/javascript";

let $allAuthors := count(doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:forename)
let $male := doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:forename[@type='male']
let $female := doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:forename[@type='female']
let $nomatch := doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:forename[@type='no-match']
return
    <authors>
        <header>Gender Distribution amongst the Forenames of the Authors</header>
        <allAuthors>{$allAuthors}</allAuthors>
        <male>
            <amount>{count($male)}</amount>
            {for $x in $male return <names>{$x/text()}</names>}   
        </male>
        <female>
            <amount>{count($female)}</amount>
            {for $x in $female return <names>{$x/text()}</names>}   
        </female>
        <nomatch>
            <amount>{count($nomatch)}</amount>
            {for $x in $nomatch return <names>{$x/text()}</names>}   
        </nomatch>
    </authors>