#!/bin/bash

collection=${1}
mode=${2}

# register configset
(cd $collection && zip -r - *) | \
curl -X POST --header 'Content-Type:application/octet-stream' --data-binary @- \
"http://localhost:8983/solr/admin/configs?action=UPLOAD&name=${collection}_set"

# create a collection
if [ $mode == "static" ]
then
    curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=1&tlogReplicas=3&maxShardsPerNode=1&collection.configName=${collection}_set"
else
    curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=3&tlogReplicas=2&maxShardsPerNode=2&collection.configName=${collection}_set&policy=policy1"
fi
