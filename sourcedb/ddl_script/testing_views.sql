CREATE OR REPLACE VIEW arp_richtplan_2017_pub.strassen_bestehend_solr_v AS
WITH 
index_base AS (
    SELECT 
        'ch.so.arp.richtplan.nationalstrassen_bestehend'::text AS subclass,
        t_id AS id_in_class,
        objectval || ' | Nr: ' || t_id || ' (Strasse Richtplan)' AS displaytext,
        objectval || ' ' || t_id  AS part_1,
        'Nationalstrasse Autobahn Strasse Richtplan Nr'::text AS part_2
    FROM
        arp_richtplan_2017_pub.strassen_bestehend
) 

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['t_id'::text], 'str:n'::text)))::text AS idfield_meta
FROM
    index_base
;


CREATE OR REPLACE VIEW agi_hoheitsgrenzen_pub.hoheitsgrenzen_bezirk_aus_gemeinden_solr_v AS
WITH 
bezirk_aus_gemeinden AS (
    SELECT 
        bezirksname
    FROM
        agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
    GROUP BY
        bezirksname
),
index_base AS (
    SELECT
        'ch.so.agi.gemeindegrenzen.bezirk'::text AS subclass,
        bezirksname AS id_in_class,
        bezirksname || ' (Bezirk)' AS displaytext,
        bezirksname AS part_1,
        'Bezirk Kreis'::text AS part_2
    FROM
        bezirk_aus_gemeinden
)

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['bezirksname'::text], 'str:y'::text)))::text AS idfield_meta
FROM
    index_base
;


CREATE OR REPLACE VIEW agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze_solr_v AS
WITH 
index_base AS (
    SELECT 
        'ch.so.agi.gemeindegrenzen'::text AS subclass,
        t_ili_tid AS id_in_class,
        gemeindename || ' | Bfs-Nr: ' || bfs_gemeindenummer || ' (Gemeinde)' AS displaytext,
        gemeindename || ' ' || bfs_gemeindenummer AS part_1,
        'Gemeinde Stadt Dorf Ort Ortschaft Bfs-Nr'::text AS part_2
    FROM
        agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
) 

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['t_id'::text], 'str:n'::text)))::text AS idfield_meta
FROM
    index_base
;

CREATE OR REPLACE VIEW agi_mopublic_pub.mopublic_grundstueck_solr_v AS
WITH 
index_base AS (
    SELECT 
        'ch.so.agi.av.grundstuecke.rechtskraeftig'::text AS subclass,
        t_id AS id_in_class,
        nbident || ', Nr: ' || nummer || ' | ' || egrid || ' (Grundstück)' AS displaytext, --todo gb_name anstelle nbident 
        nbident || ' ' ||  nummer || ' ' ||  egrid AS part_1,
        'Grundstück Parzelle Nr'::text AS part_2 --todo gemeindename ergaenzen
    FROM
        agi_mopublic_pub.mopublic_grundstueck
) 

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['t_id'::text], 'str:n'::text)))::text AS idfield_meta
FROM
    index_base
;


CREATE OR REPLACE VIEW afu_gewisso_pub.gewisso_solr_v AS
WITH 
whole_rivers AS (
    SELECT 
        gewissnr,
        "name" AS gew_name
    FROM
        afu_gewisso_pub.gewisso
    WHERE
        gewissnr IS NOT NULL 
            AND
                "name" IS NOT NULL
    GROUP BY
        gewissnr,
        gew_name
),
index_base AS (
    SELECT
        'ch.so.afu.fliessgewaesser.netz'::text AS subclass,
        gewissnr AS id_in_class,
        gew_name || ' | Nr: ' || gewissnr || ' (Fliessgewässer)' AS displaytext,
        gew_name || ' ' || gewissnr AS part_1,
        'Fliessgewässer Fluss Bach Nr'::text AS part_2
    FROM
        whole_rivers
)

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['gewissnr'::text], 'str:n'::text)))::text AS idfield_meta
FROM
    index_base
;



CREATE OR REPLACE VIEW agi_mopublic_pub.mopublic_gebaeudeadresse_solr_v AS
WITH 
index_base AS (
    SELECT 
        'ch.so.agi.av.gebaeudeadressen.gebaeudeeingaenge'::text AS subclass,
        t_id AS id_in_class,
        strassenname || ' ' || hausnummer || ', ' || plz || ' ' || ortschaft || ' (Adresse)' AS displaytext,
        strassenname || ' ' || hausnummer || ' ' || plz || ' ' || ortschaft AS part_1,
        'Adresse'::text AS part_2
    FROM
        agi_mopublic_pub.mopublic_gebaeudeadresse
) 

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 || ' ' || part_2 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['t_id'::text], 'str:y'::text)))::text AS idfield_meta
FROM
    index_base
;

CREATE OR REPLACE VIEW public.solr_index_fill_700k_v AS
WITH 
base AS (
    SELECT 
        'solr.index.fill'::text AS subclass,
        generate_series.generate_series::text AS id_in_class,
        'fill lorem ipsum solr rocks:'::text || generate_series.generate_series::text AS displaytext,
        (((random()::text || ' | '::text) || generate_series.generate_series) || ' | '::text) || random()::text AS part_1
    FROM generate_series(1, 700000) generate_series(generate_series)
)

SELECT
    (array_to_json(array_append(ARRAY[subclass::text], id_in_class::text)))::text AS id,
    displaytext AS display,
    part_1 AS search_1_stem,
    part_1 AS search_2_stem,
    part_1 AS sort,
    subclass AS facet,
    (array_to_json(array_append(ARRAY['none'::text], 'str:y'::text)))::text AS idfield_meta
FROM
    base
;

CREATE OR REPLACE VIEW agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze_nogeom_v AS
SELECT 
    t_id, 
    t_ili_tid, 
    gemeindename, 
    bfs_gemeindenummer, 
    bezirksname, 
    kantonsname
FROM agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
;