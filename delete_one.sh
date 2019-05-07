#!/bin/bash

collection=${1}
echo "Deleting ${collection} collection and configset"

# delete collection
curl "http://localhost:8983/solr/admin/collections?action=DELETE&name=${collection}"

# delete configset
curl -X DELETE "http://localhost:8983/api/cluster/configs/${collection}_set?omitHeader=true"
