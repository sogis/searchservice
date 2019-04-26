CREATE OR REPLACE VIEW public.fill_700k_v AS
WITH 
base AS (
    SELECT 
        'fill'::text AS class,
        generate_series.generate_series::text AS id_in_class,
        'fill lorem ipsum solr rocks:'::text || generate_series.generate_series::text AS display,
        (((random()::text || ' | '::text) || generate_series.generate_series) || ' | '::text) || random()::text AS search_1
    FROM generate_series(1, 700000) generate_series(generate_series)
)

SELECT
    (array_to_json(array_append(ARRAY[class::text], id_in_class::text)))::text AS id,
    display AS display,
    search_1 AS search_1,
    search_1 AS search_3,
    class AS superclass
FROM
    base
;

