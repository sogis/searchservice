CREATE OR REPLACE VIEW public.mapobj_v AS
WITH 
base AS (
    SELECT 
        class,
        id_in_class,
        displaytext,
        searchtext_1
    FROM
        searchobjects
    WHERE
        searchobjects.class IN ('ch.so.agi.av.gebaeudeadressen.gebaeudeeingaenge'::text, 'ch.so.agi.av.grundstuecke.rechtskraeftig'::text)
) 

SELECT
    (array_to_json(array_append(ARRAY[class::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    searchtext_1 AS search_1,
    searchtext_1 AS search_3,
    searchtext_1 AS sort,
    class AS superclass
FROM
    base
;