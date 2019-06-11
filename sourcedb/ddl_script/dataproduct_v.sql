
CREATE OR REPLACE VIEW gdi_knoten.dataproduct_solr_v AS
WITH 
/* 
 * dataproduct-Query liefert alle in der config-db erfassten 
 * dataproduct zurück und typisiert diese in die Subklassen
 * facadelayer, layergroup und datasetview
 */
dataproduct AS (
    SELECT
        ows_layer.gdi_oid,
        'dataproduct'::text AS facet,
        CASE facade
            WHEN TRUE THEN 'facadelayer'
            WHEN FALSE THEN 'layergroup'
            ELSE 'datasetview' -- facade NULL
        END AS subclass,
        name AS ident,
        title AS display,
        description,
        CASE 
            WHEN description IS NULL THEN FALSE
            WHEN TRIM(description) = '' THEN FALSE
            ELSE TRUE
        END AS dset_info
    FROM 
        gdi_knoten.ows_layer
    LEFT OUTER JOIN
        gdi_knoten.ows_layer_group ON ows_layer.gdi_oid = ows_layer_group.gdi_oid
    WHERE
        name != 'somap'
), 
/* 
 * Das children-Query liefert die unittelbaren Kinder
 * eines productset (layergroup, facadelayer).
 * gdi_oid_group_layer ist die ID des Parent-Layers.
 */
children AS (
    SELECT
        group_layer.gdi_oid_group_layer,
        subclass,
        ident,
        display,
        description,
        dset_info,
        group_layer.layer_order
    FROM
        dataproduct
    INNER JOIN
        gdi_knoten.group_layer ON dataproduct.gdi_oid = group_layer.gdi_oid_sub_layer
), 
/*
 * json_children erstellt mittels row_to_json(t) für jedes Kind
 * das korrespondierende JSON-Objekt und aggregiert alle
 * Kinder eines Parents mittels array_agg() und array_to_json()
 * in ein json_array der Kinder.
 * Das Attribut gid ist im JSON-Array überflüssig, stört aber auch nicht.
 */
children_json AS (
    SELECT 
        gid,
        array_to_json(array_agg(row_to_json(t))) AS json_array
    FROM (
        SELECT
            subclass,
            ident,
            display,
            dset_info,
            gdi_oid_group_layer AS gid
        FROM
            children            
    ) t 
    GROUP BY gid
),
/*
 * children_fields aggregiert die für die Suche des Parents
 * relevanten Felder der Kinder.
 */
children_fields AS (
    SELECT 
        gdi_oid_group_layer,
        array_to_json(array_agg(display)) AS display_agg,
        array_to_json(array_agg(description)) AS description_agg
    FROM
        children
    GROUP BY gdi_oid_group_layer
),
/*
 * layergroup stellt mittels join alle für eine layergroup
 * relevanten Felder zur Verfügung.
 */
layergroup AS (
    SELECT 
        dataproduct.*,
        json_array AS children_json_array,
        display_agg AS children_display_agg,
        description_agg AS children_description_agg
    FROM
        dataproduct
    INNER JOIN
        children_json ON dataproduct.gdi_oid = children_json.gid
    INNER JOIN
        children_fields ON dataproduct.gdi_oid = children_fields.gdi_oid_group_layer
    WHERE
        subclass = 'layergroup'
),
/*
 * orphans liefert datasetviews und facadelayer, welche in keinem
 * Parent-Productset enthalten sind ("Headless").
 */
orphans AS (
    SELECT
        dataproduct.*
    FROM
        dataproduct
    LEFT OUTER JOIN
        gdi_knoten.group_layer ON dataproduct.gdi_oid = group_layer.gdi_oid_sub_layer
    WHERE
        group_layer.gdi_oid_sub_layer IS NULL
        AND
            subclass != 'layergroup'     
),
/*
 * dataproduct_union vereinigt alle notwendigen Felder in eine
 * subclass-uebergreifende Datenstruktur.
 */
dataproduct_union AS (
    SELECT
        facet,
        subclass,
        ident,
        display,
        description,
        dset_info,
        children_json_array,
        children_display_agg,
        children_description_agg
    FROM
        layergroup
    UNION ALL
    SELECT
        facet,
        subclass,
        ident,
        display,
        description,
        dset_info,
        NULL AS children_json_array,
        NULL AS children_display_agg,
        NULL AS children_description_agg
    FROM
        orphans
)

/*
 * Denormalisiert die Spalten auf die notwendigen
 * Spalten des generischen tabellenübergreifenden Solr-Index.
 */
SELECT
    (array_to_json(array_append(ARRAY[subclass::text], ident::text)))::text AS id,
    display,
    children_json_array::text AS dset_children,
    dset_info,
    display AS search_1_stem,
    CONCAT(display, ', ', description, ', ', children_display_agg) AS search_2_stem,
    CONCAT(display, ', ', description, ', ', children_display_agg, ', ', children_description_agg) AS search_3_stem,
    facet
FROM
    dataproduct_union
;



