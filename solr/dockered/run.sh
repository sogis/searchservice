# The following run command starts a new container with the configuration for the index "gdi". 
# The indexed data will NOT be placed on a persistent volume --> Must be reindexed when a container is (re)started
docker run --network=host -d -P -v /home/bjsvwjek/Documents/git/searchservice/solr/configsets/gdi:/gdi_conf solr solr-create -c gdi -d /gdi_conf
