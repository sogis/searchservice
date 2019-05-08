# Skript führt ein Query mit drei Suchwörtern auf den Suchindex gdi aus.
#
# Berücksichtigt für die Sortierung (=Priorisierung) der Treffer die 
# Prioritäten der Suchfelder (search_1 > search_2 > search_3) 
# sowie der exakten Treffer versus Wildcard-Treffer mittels boosting.
# 
# date +%s%3N gibt die Systemzeit in Millisekunden aus

start=`date +%s%3N`

curl -v -G \
--data-urlencode "omitHeader=true" \
--data-urlencode "fq=(search_3:*$1* AND search_3:*$2* AND search_3:*$3*)" \
--data-urlencode "q=( (search_1:$1^6 OR search_1:*$1*^5) AND (search_1:$2^6 OR search_1:*$2*^5) AND (search_1:$3^6 OR search_1:*$3*^5) )" \
--data-urlencode "OR ( (search_2:$1^4 OR search_2:*$2*^3) AND (search_2:$2^4 OR search_2:*$2*^3) AND (search_2:$3^4 OR search_2:*$3*^3) )" \
--data-urlencode "OR ( (search_3:$1^2 OR search_3:*$2*^1) AND (search_3:$2^2 OR search_3:*$2*^1) AND (search_3:$3^2 OR search_3:*$3*^1) )" \
--data-urlencode "fl=display" \
--data-urlencode "facet=true" \
--data-urlencode "facet.field=superclass" \
http://localhost:8983/solr/gdi/select

end=`date +%s%3N`
millis=`expr $end - $start`

echo "Query took Solr $millis milliseconds to process"






