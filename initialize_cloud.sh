#!/bin/bash

# untar solr-7.5.0.tgz
# mkdir node1 node2
# cp solr-7.5.0/server/solr/solr.xml solr-7.5.0/server/solr/zoo.cfg node1
# cp solr-7.5.0/server/solr/solr.xml solr-7.5.0/server/solr/zoo.cfg node2
# overwrite SOLR_ULIMIT_CHECKS to 65000 in solr.in.sh
# ./solr7/bin/solr start -c -p 8983 -s _PATH_TO_node1
# ./solr7/bin/solr start -c -p 7574 -z localhost:9983 -s _PATH_TO_node2

# add more nodes for replica
# mkdir node3 node4
# cp solr-7.5.0/server/solr/solr.xml solr-7.5.0/server/solr/zoo.cfg node3
# cp solr-7.5.0/server/solr/solr.xml solr-7.5.0/server/solr/zoo.cfg node4
# ./solr7/bin/solr start -c -p 6765 -z localhost:9983 -s /Users/hsyoo/Applications/solr_cloud/node3
# ./solr7/bin/solr start -c -p 5654 -z localhost:9983 -s /Users/hsyoo/Applications/solr_cloud/node4
# curl 'localhost:8983/solr/admin/collections?action=ADDREPLICA&collection=genome_feature&shard=shard1&node=130.202.148.146:6765_solr'
# curl 'localhost:8983/solr/admin/collections?action=ADDREPLICA&collection=genome_feature&shard=shard2&node=130.202.148.146:5654_solr'

collections=(antibiotics enzyme_class_ref feature_sequence gene_ontology_ref genome genome_amr genome_feature genome_sequence id_ref misc_niaid_sgc model_complex_role model_compound model_reaction model_template_biomass model_template_reaction pathway pathway_ref ppi protein_family_ref sp_gene sp_gene_evidence sp_gene_ref structured_assertion subsystem subsystem_ref taxonomy transcriptomics_experiment transcriptomics_gene transcriptomics_sample)
# collections=(genome genome_feature genome_sequence feature_sequence pathway subsystem)
# collections=(genome)
for collection in "${collections[@]}"
do
    # register configset
    (cd $collection && zip -r - *) | \
    curl -X POST --header 'Content-Type:application/octet-stream' --data-binary @- \
     "http://localhost:8983/solr/admin/configs?action=UPLOAD&name=${collection}_set"
    # create a collection
    # curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=2&replicationFactor=2&tlogReplicas=1&collection.configName=${collection}_set"
    curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=2&replicationFactor=1&collection.configName=${collection}_set"
done
