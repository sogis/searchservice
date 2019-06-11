-- Start shell in docker
docker exec -it pgdev /bin/bash

-- create the dump
pg_dump --host localhost --dbname dev --username postgres --format custom --file tmp/suche_testdata.dmp
