#!/bin/bash

echo "=========================================================="
echo "Docker container for test PostgreSQL database with postgis"
echo "Uses the following Docker image:"
echo "https://hub.docker.com/r/mdillon/postgis"
echo "=========================================================="

docker run -it \
    --name pgdev \
    -e POSTGRES_PASSWORD=admin1234 \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v $(pwd)/pgdata:/var/lib/postgresql/data/pgdata \
    -v $(pwd)/tmp:/tmp \
    -p 5432:5432 \
    --rm \
    pgdev
