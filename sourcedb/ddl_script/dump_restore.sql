-- Start shell in docker
docker exec -it pgdev /bin/bash

-- 1.0 Restore metadata
-- 1.1 Create schema gdi_knoten in dbeaver
CREATE SCHEMA gdi_knoten;
-- 1.2 Restore into gdi_knoten. Not in transaction, as is dirty restore of only gdi_knoten data
pg_restore --clean --host=localhost --dbname=dev --username=postgres --password --no-owner --no-privileges --schema=gdi_knoten /tmp/soconfig_geodb.rootso.org.dmp


-- 2.0 Restore geodata
-- 2.1 Create empty schematas in dbeaver
CREATE SCHEMA IF NOT EXISTS arp_richtplan_2017_pub;
CREATE SCHEMA IF NOT EXISTS agi_mopublic_pub;
CREATE SCHEMA IF NOT EXISTS afu_gewisso_pub;
CREATE SCHEMA IF NOT EXISTS agi_hoheitsgrenzen_pub;
CREATE SCHEMA IF NOT EXISTS afu_gewaesserschutz_pub;
CREATE SCHEMA IF NOT EXISTS afu_altlasten_pub;
-- 2.2 Restore the schematas
pg_restore --clean --host=localhost --dbname=dev --username=postgres --password --no-owner --no-privileges --schema=arp_richtplan_2017_pub --schema=agi_mopublic_pub --schema=afu_gewisso_pub --schema=agi_hoheitsgrenzen_pub --schema=afu_gewaesserschutz_pub --schema=afu_altlasten_pub /tmp/pub_geodb.rootso.org.dmp
