# Skript führt ein Query mit drei Suchwörtern auf den Suchindex gdi aus.
#
# Berücksichtigt für die Sortierung (=Priorisierung) der Treffer die 
# Prioritäten der Suchfelder (search_1 > search_2 > search_3) 
# sowie der exakten Treffer versus Wildcard-Treffer mittels boosting.
# 
# Verstehe nur so halbwegs, wieso es ohne zweites fq auf search_1 - _3
# deutlich besser performt...
# Zweites fq: "fq=(search_3:*$1* AND search_3:*$2* AND search_3:*$3*)" \
# 
# date +%s%3N gibt die Systemzeit in Millisekunden aus

start=`date +%s%3N`

curl -v -G \
--data-urlencode "omitHeader=true" \
--data-urlencode "fq=(facet:dataproduct OR facet:background)" \
--data-urlencode "q=(search_1_stem:$1^6 OR search_1_ngram:$1^5)" \
--data-urlencode "OR (search_2_stem:$1^4 OR search_2_ngram:$1^3)"\
--data-urlencode "OR (search_3_stem:$1^2 OR search_3_ngram:$1^1)"\
--data-urlencode "fl=display" \
--data-urlencode "facet=true" \
--data-urlencode "facet.field=facet" \
--data-urlencode "start=0" \
--data-urlencode "rows=20" \
http://solr-headless-solr-cloud-integration.dev.so.ch/solr/gdi/select

end=`date +%s%3N`
millis=`expr $end - $start`

echo "Query took Solr $millis milliseconds to process"

#--data-urlencode "fq=(facet:dataproduct OR facet:ch.so.agi.gemeindegrenzen OR facet:ch.so.agi.av.gebaeudeadressen.gebaeudeeingaenge)" \





