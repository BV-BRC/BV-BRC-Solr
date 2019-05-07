#!/bin/bash

# 16 static collections
collections=(antibiotics enzyme_class_ref gene_ontology_ref misc_niaid_sgc model_complex_role model_compound model_reaction model_template_biomass model_template_reaction pathway_ref sp_gene_evidence sp_gene_ref subsystem_ref taxonomy transcriptomics_experiment transcriptomics_sample transcriptomics_gene)
for collection in "${collections[@]}"
do
    # register configset
    (cd $collection && zip -r - *) | \
    curl -X POST --header 'Content-Type:application/octet-stream' --data-binary @- \
     "http://localhost:8983/solr/admin/configs?action=UPLOAD&name=${collection}_set"
    # create a collection
    curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=1&tlogReplicas=3&maxShardsPerNode=1&collection.configName=${collection}_set"
done

# setup policy
curl "http://localhost:8983/solr/admin/autoscaling" -X POST -d '{"remove-policy": "policy1"}'
curl "http://localhost:8983/solr/admin/autoscaling" -X POST -d @policy.input.json

# 5 large static, 8 dynamic collections
collections=(feature_sequence genome genome_amr genome_feature genome_sequence id_ref pathway ppi protein_family_ref sp_gene structured_assertion subsystem)
for collection in "${collections[@]}"
do
    # register configset
    (cd $collection && zip -r - *) | \
    curl -X POST --header 'Content-Type:application/octet-stream' --data-binary @- \
     "http://localhost:8983/solr/admin/configs?action=UPLOAD&name=${collection}_set"
    # create a collection
    curl "http://localhost:8983/solr/admin/collections?action=CREATE&name=${collection}&numShards=3&tlogReplicas=2&maxShardsPerNode=2&collection.configName=${collection}_set&policy=policy1"
done
