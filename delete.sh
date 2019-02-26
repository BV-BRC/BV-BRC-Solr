#!/bin/bash

collections=(antibiotics enzyme_class_ref feature_sequence gene_ontology_ref genome genome_amr genome_feature genome_sequence id_ref misc_niaid_sgc model_complex_role model_compound model_reaction model_template_biomass model_template_reaction pathway pathway_ref ppi protein_family_ref sp_gene sp_gene_evidence sp_gene_ref structured_assertion subsystem subsystem_ref taxonomy transcriptomics_experiment transcriptomics_gene transcriptomics_sample)

# collections=(genome genome_feature genome_sequence feature_sequence pathway subsystem)
# collections=(genome)
for collection in "${collections[@]}"
do
    # delete collection
    curl "http://localhost:8983/solr/admin/collections?action=DELETE&name=${collection}"
    # delete configset
    curl -X DELETE "http://localhost:8983/api/cluster/configs/${collection}_set?omitHeader=true"
done
