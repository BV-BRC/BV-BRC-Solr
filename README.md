# Solr Cloud Config Set for PATRIC

For solr cloud, you need to use Configsets API and Collections API to configure a collection.
## 1. Create a ConfigSet
```
$ (cd genome && zip -r - *) | \
 curl -X POST --header 'Content-Type:application/octet-stream' --data-binary @- \
 'http://localhost:8983/solr/admin/configs?action=UPLOAD&name=genome_set'
```
You can lookup what configsets are available,
```
curl http://localhost:8983/api/cluster/configs'
```
or delete
```
curl -X DELETE 'http://localhost:8983/api/cluster/configs/genome_set?omitHeader=true'
```
For more detail, <https://lucene.apache.org/solr/guide/7_5/configsets-api.html>


## 2. After a config set is registered, you can initialize a collection as below,
```
$ curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=genome&numShards=1&replicationFactor=1&collection.configName=genome_set'
```
with numShards, and replicationFactor.
For more detail, refer the Collections API <https://lucene.apache.org/solr/guide/7_5/collections-api.html>
