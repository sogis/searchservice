
CREATE OR REPLACE VIEW gdi_knoten.dataprod_solr_v AS
WITH 
/* 
 * dataproduct-Query liefert alle in der config-db erfassten 
 * dataproduct zurück und typisiert diese in die Subklassen
 * facadelayer, layergroup und datasetview
 */
dataproduct AS (
    SELECT
        ows_layer.gdi_oid,
        'dataproduct'::text AS superclass,
        CASE facade
            WHEN TRUE THEN 'facadelayer'
            WHEN FALSE THEN 'layergroup'
            ELSE 'datasetview' -- facade NULL
        END AS subclass,
        name AS ident,
        title,
        description
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
        title,
        description,
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
            title,
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
        array_to_json(array_agg(title)) AS title_agg,
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
        title_agg AS children_title_agg,
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
        superclass,
        subclass,
        ident,
        title,
        description,
        children_json_array,
        children_title_agg,
        children_description_agg
    FROM
        layergroup
    UNION ALL
    SELECT
        superclass,
        subclass,
        ident,
        title,
        description,
        NULL AS children_json_array,
        NULL AS children_title_agg,
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
    title AS display,
    children_json_array::text AS dset_children,
    CASE 
        WHEN description IS NULL THEN FALSE
        WHEN TRIM(description) = '' THEN FALSE
        ELSE TRUE
    END AS dset_info,
    title AS search_1,
    CONCAT(title, ', ', description, ', ', children_title_agg) AS search_2,
    CONCAT(title, ', ', description, ', ', children_title_agg, ', ', children_description_agg) AS search_3,
    superclass
FROM
    dataproduct_union
;



