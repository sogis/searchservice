
/*
 * ZU BEACHTEN:
 * Die View referenziert die WMS und WFS-Root Layer über
 * deren ids 2 und 4. 
 * Grund: Zum Zeitpukt der Viewerstellung existiert
 * für diese keine nutzbaren stabilen Identifikatoren.
 */
CREATE OR REPLACE VIEW gdi_knoten.layer_base_solr_v AS
WITH
/*
 * Liefert die Namen (Name, Kuerzel) der Organisationen
 */
orgnames AS (
	SELECT
		organisation.id,
		concat_ws(' ', contact.name, organisation.abbreviation) AS org_names
	FROM
		contacts.organisation
	INNER JOIN 
		contacts.contact ON organisation.id = contact.id
),
/*
 * Liefert die Organisationsnamen aller Kontakte.
 * 
 * Bei Kontakttyp 'organisation' direkt, bei Kontakttyp
 * 'person' über die der Person zugeordnete Organisation.
 */
contact_orgnames AS (
	SELECT
		id,
		org_names
	FROM
		orgnames
	UNION ALL
	SELECT
		pers.id,
		orgnames.org_names
	FROM
		contacts.contact AS pers
		INNER JOIN 
			orgnames ON pers.id_organisation = orgnames.id
	WHERE  
		lower(pers.TYPE::text) = 'person'
),
/*
 * Liefert die einer GDI-Ressource zugeordneten Organisationsnamen für
 * Kontakte des Typs 'datenherr'
 */
resource_owner_orgs AS (
	SELECT
		gdi_oid_resource,
		org_names
	FROM
		contacts.resource_contact
	INNER JOIN
		contacts.contact_role ON resource_contact.id_contact_role = contact_role.id
	INNER JOIN
		contact_orgnames ON resource_contact.id_contact = contact_orgnames.id
	WHERE 
		LOWER(contact_role.type) = 'datenherr'
),
/* 
 * dataproduct-Query liefert alle in der config-db erfassten 
 * dataproduct zurück und typisiert diese in die Subklassen
 * facadelayer, layergroup und datasetview
 */
dataproduct AS (
    SELECT
        ows_layer.gdi_oid,
	    CASE
	        WHEN LOWER(name) in (
	        	'ch.so.agi.grundbuchplan_farbig', 
	        	'ch.so.agi.grundbuchplan_sw', 
	        	'ch.so.agi.hintergrundkarte_farbig', 
	        	'ch.so.agi.hintergrundkarte_ortho', 
	        	'ch.so.agi.hintergrundkarte_sw') 
	        		THEN 'background'
	        ELSE 'dataproduct'
	    END AS facet,
        CASE facade
            WHEN TRUE THEN 'facadelayer'
            WHEN FALSE THEN 'layergroup'
            ELSE 'datasetview' -- facade NULL
        END AS subclass,
        name AS ident,
        title AS display,
        synonyms,
        CONCAT_WS(', ', keywords, 'karte', 'ebene', 'layer') AS keywords,
        CONCAT_WS(', ', ows_metadata, org_names) AS desc_org, 
        CASE 
            WHEN ows_metadata IS NULL THEN FALSE
            WHEN TRIM(ows_metadata) = '' THEN FALSE
            ELSE TRUE
        END AS dset_info
    FROM 
        gdi_knoten.ows_layer
    LEFT OUTER JOIN
        gdi_knoten.ows_layer_group ON ows_layer.gdi_oid = ows_layer_group.gdi_oid
    LEFT OUTER JOIN
    	resource_owner_orgs ON ows_layer.gdi_oid = resource_owner_orgs.gdi_oid_resource
    WHERE
        ows_layer.gdi_oid NOT IN (2,4)
        AND
		    name NOT IN ('ch.so.afu.baugk.geschaefte')  /* Weitere folgen in Kuerze --> NOT IN */
), 
/*
 * Liefert alle zu einem productset zugehörigen Kinder
 */
productset_childrenids AS (
	SELECT
		gdi_oid_sub_layer AS child_gdi_oid,
		layer_order AS child_order_in_parent,
		gdi_oid_group_layer AS parent_gdi_oid,
		dataproduct.subclass AS parent_subclass
	FROM
		gdi_knoten.group_layer
			INNER JOIN dataproduct ON group_layer.gdi_oid_group_layer = dataproduct.gdi_oid
),
/* 
 * Das children-Query liefert die unittelbaren Kinder
 * einer layergroup.
 * gdi_oid_group_layer ist die ID der layergroup.
 */
children_with_parents AS (
    SELECT
        productset_childrenids.parent_gdi_oid AS gdi_oid_group_layer,
        dataproduct.subclass,
        ident,
        display,
        synonyms,
        keywords,
        desc_org,
        dset_info,
        productset_childrenids.child_order_in_parent AS layer_order
    FROM
        dataproduct
    INNER JOIN
    	productset_childrenids ON dataproduct.gdi_oid = productset_childrenids.child_gdi_oid
    WHERE 
    	productset_childrenids.parent_subclass = 'layergroup'
), 
/*
 * non_orphans_json erstellt mittels row_to_json(t) für jedes Kind
 * das korrespondierende JSON-Objekt und aggregiert alle
 * Kinder eines Parents mittels array_agg() und array_to_json()
 * in ein json_array der Kinder.
 * Das Attribut gid ist im JSON-Array überflüssig, stört aber auch nicht.
 */
children_with_parents_json AS (
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
            children_with_parents       
        ORDER BY
        	layer_order
    ) t 
    GROUP BY gid
),
/*
 * non_orphans_fields aggregiert die für die Suche des Parents
 * relevanten Felder der Kinder.
 */
children_with_parents_fields AS (
    SELECT 
        gdi_oid_group_layer,
        array_to_json(array_agg(display)) AS display_agg,
        array_to_json(array_agg(synonyms)) AS synonyms_agg,
        array_to_json(array_agg(keywords)) AS keywords_agg,
        array_to_json(array_agg(desc_org)) AS desc_org_agg
    FROM
        children_with_parents
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
        synonyms_agg AS children_synonyms_agg,
        keywords_agg AS children_keywords_agg,
        desc_org_agg AS children_desc_org_agg
    FROM
        dataproduct
    INNER JOIN
        children_with_parents_json ON dataproduct.gdi_oid = children_with_parents_json.gid
    INNER JOIN
        children_with_parents_fields ON dataproduct.gdi_oid = children_with_parents_fields.gdi_oid_group_layer
    WHERE
		subclass = 'layergroup'
),
/*
 * Sagt aus, ob für das dataproduct ein oder mehrere parents
 * existieren, und ob unter den parents ein facadelayer ist.
 */
parent_ps_info AS (
	SELECT 
		group_layer.gdi_oid_sub_layer,
		max(ows_layer_group.facade::int) AS has_facade_parent
	FROM
		gdi_knoten.ows_layer_group
			INNER JOIN gdi_knoten.group_layer ON ows_layer_group.gdi_oid = group_layer.gdi_oid_group_layer
	WHERE 
		gdi_oid NOT IN (2,4)
	GROUP BY
		group_layer.gdi_oid_sub_layer
),
/*
 * Alle dataproducts, welche 
 * das Flag "in WMS verfügbar"
 * gesetzt haben.
 */
wms_flagged_dataproducts AS (
	SELECT
		gdi_oid_sub_layer AS gdi_oid_in_wms
	FROM
		gdi_knoten.group_layer
	WHERE 
		group_layer.gdi_oid_group_layer = 2
),
/*
 * Gibt im attribut stands_alone an, ob ein dataproduct aufgrund
 * seiner Konfiguration als separates Dokument indexiert wird oder nicht.
 */
standalone_dataproduct AS (
	SELECT
		ows_layer.gdi_oid,
		CASE
			WHEN has_facade_parent IS NULL AND gdi_oid_in_wms IS NOT NULL THEN TRUE --kein parent
			WHEN has_facade_parent IS NULL AND gdi_oid_in_wms IS NULL THEN FALSE -- z.B: .data
			WHEN has_facade_parent = 1 AND gdi_oid_in_wms IS NOT NULL THEN TRUE 
			WHEN has_facade_parent = 0 THEN FALSE --layergroup als parent
			ELSE NULL
		END AS stands_alone,
		parent_ps_info.has_facade_parent
	FROM 
		gdi_knoten.ows_layer
			LEFT OUTER JOIN
				wms_flagged_dataproducts ON ows_layer.gdi_oid = wms_flagged_dataproducts.gdi_oid_in_wms
			LEFT OUTER JOIN 
				parent_ps_info ON ows_layer.gdi_oid = parent_ps_info.gdi_oid_sub_layer
),
/*
 * Liefert facadelayer und datasetviews, welche als für sich stehende Dokumente
 * in den Solr index aufgenommen werden.
 */
singlerow_standalone AS (
    SELECT
        dataproduct.*
    FROM
        dataproduct
    	INNER JOIN 
    		standalone_dataproduct ON dataproduct.gdi_oid = standalone_dataproduct.gdi_oid
    WHERE 
    	dataproduct.subclass != 'layergroup'
    		AND
    			standalone_dataproduct.stands_alone = true
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
        synonyms,
        keywords,
        desc_org,
        dset_info,
        children_json_array,
        children_display_agg,
        children_synonyms_agg,
        children_keywords_agg,
        children_desc_org_agg
    FROM
        layergroup
    UNION ALL
    SELECT
        facet,
        subclass,
        ident,
        display,
        synonyms,
        keywords,
        desc_org,
        dset_info,
        NULL AS children_json_array,
        NULL AS children_display_agg,
        NULL AS children_synonyms_agg,
        NULL AS children_keywords_agg,
        NULL AS children_desc_org_agg
    FROM
        singlerow_standalone
)

/*
 * Denormalisiert die Spalten auf die notwendigen
 * Spalten des generischen tabellenübergreifenden Solr-Index.
 */
SELECT
    (array_to_json(ARRAY[subclass::text, ident::TEXT]))::text AS id,
    display,
    children_json_array::text AS dset_children,
    dset_info,
    CONCAT_WS(', ', display, synonyms)  AS search_1_stem,
    CONCAT_WS(', ', display, synonyms, desc_org, keywords, children_display_agg, children_synonyms_agg) AS search_2_stem,
    CONCAT_WS(', ', display, synonyms, desc_org, keywords, children_display_agg, children_synonyms_agg, 
    children_keywords_agg, children_desc_org_agg) AS search_3_stem,
    facet
FROM
    dataproduct_union
WHERE children_desc_org_agg::text LIKE '%asleit%'
;

/*
 * Tests:
 * - Facadelayer als Waise: WHERE display LIKE '%Störfall%'
 * - Facadelayer mit Parent: WHERE children_json_array::text LIKE '%Wald (Nutz%'
 * - Datasetview als Waise: WHERE display LIKE '%Baugrund%'
 * - Dataserview mit Parent: WHERE children_json_array::text LIKE '%Pleisto%'
 * - Layergroup: WHERE display LIKE '%Geol%' 
 * 
 * - Prüfperimeter Bodenabtrag
 */

/*
 * View für das Indexieren der für WGC und Qgis Desktop
 * relevanten layer
 */
CREATE OR REPLACE VIEW gdi_knoten.layer_dataproduct_solr_v AS
SELECT
	*
FROM
	gdi_knoten.layer_base_solr_v
WHERE
	facet = 'dataproduct'
;
	
/*
 * View für das Indexieren der nur für Qgis Desktop
 * zusätzlich relevanten Hintergrundebenen
 */
CREATE OR REPLACE VIEW gdi_knoten.layer_background_solr_v AS
SELECT
	*
FROM
	gdi_knoten.layer_base_solr_v
WHERE
	facet = 'background'
;