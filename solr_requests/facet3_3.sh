# query for to terms in all three search fields with boosting

date +%s%3N

curl -G \
--data-urlencode "omitHeader=true" \
--data-urlencode "fq=(search_3:*$1* AND search_3:*$2* AND search_3:*$3*)" \
--data-urlencode "q=(search_1:*$1*^2 AND search_1:*$2*^2 AND search_1:*$3*^2) OR (search_2:*$1* AND search_2:*$2* AND search_2:$3*) OR (search_3:*$1*^0.5 AND search_3:*$2*^0.5 AND search_3:*$3*^0.5)" \
--data-urlencode "fl=display" \
--data-urlencode "facet=true" \
--data-urlencode "facet.field=superclass" \
http://localhost:8983/solr/gdi/select

date +%s%3N






