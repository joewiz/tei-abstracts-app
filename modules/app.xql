xquery version "3.0";
module namespace app="http://www.digital-archiv.at/ns/tei-abstracts/templates";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = 'http://www.functx.com';
declare namespace util = "http://exist-db.org/xquery/util";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://www.digital-archiv.at/ns/tei-abstracts/config" at "config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
declare function functx:substring-after-last
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
    replace ($arg,concat('^.*',$delim),'')
 };


(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

(:~
: returns the name of the document of the node passed to this function.
:)
declare function app:getDocName($node as node()){
let $name := functx:substring-after-last(document-uri(root($node)), '/')
    return $name
};

(:~
 : href to document.
 :)
declare function app:hrefToDoc($node as node()){
let $name := functx:substring-after-last($node, '/')
let $href := concat('show.html','?document=', app:getDocName($node))
    return $href
};

(:~
 : a fulltext-search function
 :)
 declare function app:ft_search($node as node(), $model as map (*)) {
 if (request:get-parameter("searchexpr", "") !="") then
 let $searchterm as xs:string:= request:get-parameter("searchexpr", "")
 for $hit in collection(concat($config:app-root, '/data/'))//*[.//tei:p[ft:query(.,$searchterm)]|.//tei:cell[ft:query(.,$searchterm)] | .//tei:msDesc[ft:query(.,$searchterm)]]
    let $doc := document-uri(root($hit))
    let $type := tokenize($doc,'/')[(last() - 1)]
    let $params := concat("&amp;directory=", $type, "&amp;stylesheet=", $type)
    let $href := concat(app:hrefToDoc($hit), "&amp;searchexpr=", $searchterm, $params) 
    let $score as xs:float := ft:score($hit)
    order by $score descending
    return
    <tr>
        <td>{$score}</td>
        <td class="KWIC">{kwic:summarize($hit, <config width="40" link="{$href}" />)}</td>
        <td>{app:getDocName($hit)}</td>
    </tr>
 else
    <div>Nothing to search for</div>
 };

(:~
 : fetches all documents which contain the searched entity
 :)
declare function app:registerBasedSearch_hits($node as node(), $model as map(*), $searchkey as xs:string?, $path as xs:string?)
{
for $title in collection(concat($config:app-root, '/data/editions'))//tei:TEI[.//tei:author[.//*[@*=$searchkey]]]
    let $doc := document-uri(root($title))
    let $type := tokenize($doc,'/')[(last() - 1)]
    let $params := concat("&amp;directory=", $type, "&amp;stylesheet=", $type)
    return
    <tr>
        <td>
            <a href="{concat(app:hrefToDoc($title),$params)}">{$title//tei:titleStmt/tei:title/text()}</a>
        </td>
    </tr> 
 };
  
 (:~
 : creates a basic organisation-index derived from the  '/data/indices/listorg.xml'
 :)
declare function app:listOrg($node as node(), $model as map(*)) {
    let $listperson := doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:TEI
    for $org in doc(concat($config:app-root, '/data/indices/listorg.xml'))//tei:listOrg/tei:org
    let $id := $org/tei:orgName
    let $doc := document-uri(root($org))
    let $type := tokenize($doc,'/')[(last() - 1)]
    let $params := concat("&amp;directory=", $type, "&amp;stylesheet=listorg&amp;id=", $id)
    let $country := $org//tei:country
    order by $country
        return
        <tr>
            <td>
                <a href="{concat(app:hrefToDoc($listperson),$params)}">{$org/tei:orgName}</a>
            </td>
            <td>
                {$country}
            </td>
        </tr>
};
 
(:~
 : creates a basic bibl-index derived from the  '/data/indices/listbibl.xml'
 :)
declare function app:listBibl($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $bibl in doc(concat($config:app-root, '/data/indices/listbibl.xml'))//tei:item
        return
        <tr>
            <td>
                <a href="{concat($hitHtml,$bibl/tei:label)}">{$bibl}</a>
            </td>
        </tr>
};
 
(:~
 : creates a basic place-index derived from the  '/data/indices/listplace.xml'
 :)
declare function app:listPlace($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey=pla:"
    for $place in doc(concat($config:app-root, '/data/indices/listplace.xml'))//tei:listPlace/tei:place
        return
        <tr>
            <td>
                <a href="{concat($hitHtml,data($place/@xml:id))}">{$place/tei:placeName}</a>
            </td>
            <td>{$place//tei:idno}</td>
            <td><geo>{replace($place//tei:geo/text(),',','|')}</geo></td>
        </tr>
};
 
(:~
 : creates a basic book-index derived from the  '/data/indices/listbook.xml'
 :)
declare function app:listBook($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey=boo:"
    for $item in doc(concat($config:app-root, '/data/indices/listbook.xml'))//tei:bibl
    order by $item//tei:surname
        return
        <tr>
            <td>
                <a href="{concat($hitHtml,data($item/@xml:id))}">{$item/tei:author}</a>
            </td>
            <td>{$item//tei:title[@type='full']/text()}</td>
            <td>{$item//tei:pubPlace}</td>
            <td>{$item//tei:date}</td>
        </tr>
};

(:~
 : creates a basic person-index derived from the  '/data/indices/listperson.xml'
 :)
declare function app:listPers($node as node(), $model as map(*)) {
    let $hitHtml := "hits.html?searchkey="
    for $person in doc(concat($config:app-root, '/data/indices/listperson.xml'))//tei:listPerson/tei:person
    let $ref := data($person/tei:persName/@key)
    let $viaf := if (starts-with($ref, 'http')) then <a href="{$ref}">{$ref}</a> else 'no viaf yet provided'
    order by $person//tei:surname
        return
        <tr>
            <td><a href="{concat($hitHtml,data($person//@key)[1])}">{$person//tei:surname}</a></td>
            <td>{$person//tei:forename}</td>
            <td>{data($person//tei:forename/@type)}</td>
            <td>{$person//tei:orgName}</td>
            <td>{$person//tei:country}</td>
            <td>{$viaf}</td>
        </tr>
};

(:~
 : creates a basic table of content derived from the documents stored in '/data/editions'
 :)
declare function app:toc($node as node(), $model as map(*)) {
    for $doc in (collection(concat($config:app-root, '/data/editions'))//tei:TEI, collection(concat($config:app-root, '/data/descriptions'))//tei:TEI)
    let $collection := functx:substring-after-last(util:collection-name($doc), '/')
    let $authors := $doc//tei:titleStmt/tei:author//tei:persName
    let $title := $doc//tei:titleStmt/tei:title[1]
    let $type := $doc//tei:keywords[1]/tei:term[1]
    let $keywords := string-join($doc//tei:keywords[2]/tei:term, ' | ')
    
        return
        <tr>
            <td>{for $x in $authors return <li class="list-unstyled">{$x}</li>}</td>
            <td>
                <a href="{concat(app:hrefToDoc($doc),'&amp;directory=',$collection,'&amp;stylesheet=',$collection)}">
                    {$title//text()}
                </a>
            </td>
            <td>
                {$type}
            </td>
            <td>
                {$keywords}
            </td>
        </tr>   
};

(:~
 : perfoms an XSLT transformation
:)
declare function app:XMLtoHTML ($node as node(), $model as map (*), $query as xs:string?) {
let $ref := xs:string(request:get-parameter("document", ""))
let $xmlPath := concat(xs:string(request:get-parameter("directory", "editions")), '/')
let $xml := doc(replace(concat($config:app-root,'/data/', $xmlPath, $ref), '/exist/', '/db/'))
let $xslPath := concat(xs:string(request:get-parameter("stylesheet", "editions")), '.xsl')
let $xsl := doc(replace(concat($config:app-root,'/resources/xslt/', $xslPath), '/exist/', '/db/'))
let $params := 
<parameters>
   {for $p in request:get-parameter-names()
    let $val := request:get-parameter($p,())
    where  not($p = ("document","directory","stylesheet"))
    return
       <param name="{$p}"  value="{$val}"/>
   }
</parameters>
return 
    transform:transform($xml, $xsl, $params)
};


(:~
 : creates a basic table of content derived from the documents stored in '/data/editions'
 :)
declare function app:showEntityInfo($node as node(), $model as map(*)) {
    let $ref := xs:string(request:get-parameter("entityID", ""))
    let $element := collection(concat($config:app-root,'/data/indices/'))//*[@xml:id=$ref]
    for $x in $element
    return
        $x
};