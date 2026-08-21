# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

Solr configsets for the BV-BRC (formerly PATRIC) data platform. There is no build, no test suite, and no application code — the repository *is* the deployable artifact. Each top-level directory is one Solr collection's configset, containing exactly two files:

- `managed-schema` — the field definitions (hand-edited XML, despite the "managed" name; the schema API is not used)
- `solrconfig.xml` — almost always a **symlink** into `sharedConfig/`

40 collections are defined. `sharedConfig/` is not a collection.

## Deploy commands

Everything targets a Solr Cloud node at `http://localhost:8983` (use an SSH tunnel to reach a real cluster). A configset is uploaded as a zip of the *contents* of a collection directory — note the `(cd $collection && zip -r - *)` idiom, which resolves the `solrconfig.xml` symlink into the archive.

```bash
./create_one.sh <collection> static            # 1 shard, 3 tlog replicas
./create_one.sh <collection> dynamic <shards>  # N shards, 1 tlog replica
./delete_one.sh <collection>                   # drops collection AND configset
./initialize_cloud.sh                          # full bootstrap of a fresh cluster
./delete.sh                                    # drops the whole standard collection set
```

To push a schema change to an existing collection without recreating it, upload the configset under a new name (or with `&overwrite=true`), point the collection at it, and RELOAD:

```bash
curl "http://localhost:8983/solr/admin/collections?action=RELOAD&name=<collection>"
```

Adding a stored field to a live collection generally requires a reindex; changing a field's type or `multiValued` flag **always** does.

## Editing conventions

**solrconfig.xml is shared, not per-collection.** Three variants exist and the only difference between them is the update chain:

| Variant | Behavior | Used by |
|---|---|---|
| `sharedConfig/solrconfig.xml` | plain `/update`, caller supplies the key | collections with a natural key |
| `sharedConfig/solrconfig.keygen.xml` | `UUIDUpdateProcessorFactory` auto-fills `id` | the ~24 collections whose `uniqueKey` is `id` |
| `genome_sequence/solrconfig.xml` | local copy; UUID chain on `sequence_id` | `genome_sequence` only |

Never copy a solrconfig into a collection directory to make a one-off tweak — that was done historically and has since been reverted to symlinks (see commits `d24a517`, `28fd3b2`). If a collection needs UUID keys, rename its key field to `id` and re-point the symlink at `solrconfig.keygen.xml`.

**Field types are duplicated verbatim in all 40 schemas.** The `<fieldType>` block in each `managed-schema` is a copy-pasted boilerplate set (`string`, `string_ci`, `text_custom`, point-numeric types, …). A change to a shared type must be applied to every schema that uses it, or the collections will diverge. Two variants of `string_ci` are already in the wild — some with `docValues="true"`, some without — so check before assuming.

Key types:
- `string_ci` — `SortableTextField`, keyword-tokenized + lowercased + `WordDelimiterGraph`. This is the default for human-readable metadata; it sorts like a string but matches case-insensitively.
- `text_custom` — the analyzed catch-all that `text` fields use as the free-text search target.
- `rdate` — `DateRangeField`, currently only `genome.collection_date_dr` (non-stored, indexed only for range queries against the free-text `collection_date`).

**Where the fieldType block goes.** Older schemas put `<fields>` first and `<fieldType>` definitions at the bottom; the newest ones (`genome_typing`, `private_genome_metadata`) put types first, with the comment "must come before fields in Solr 9.x" — the result of commit `aefe384`. Put types first in new schemas.

**Every schema carries the same tail block:** `text` (the copyField sink), `_version_`, and `date_inserted` / `date_modified` (`pdate`, `default="NOW"`). Ten collections additionally carry the privilege-control quartet `public` / `owner` / `user_read` / `user_write`; add it to any collection that will hold private user data.

**copyField into `text`** is how BV-BRC's global keyword search works. Eight schemas use the blanket `<copyField source="*" dest="text"/>`; the rest enumerate specific source fields. Follow whichever style the file already uses. A few schemas also copy a string key into a parallel `_i` int field (e.g. `taxon_id` → `taxon_id_i`) so it can be sorted numerically.

**Deprecated fields are commented, not deleted** (`<!-- deprecated -->`). They stay in the schema because live indexes still contain the data. Preserve them.

## Schema-breaking changes and versioned collections

When a change requires a full dump-and-reindex, the convention is to load into a versioned collection and alias it. From the May 2026 `genome.segment` → multiValued change (README "Change history"):

```
load → genome_v02 → CREATEALIAS genome -> genome_v02
```

Record the change and its reason in the README's "Change history" section as part of the same commit.

## Solr version caveats

`luceneMatchVersion` is `8.8.1`. The deploy scripts still use Solr 7/8-era APIs that were **removed in Solr 9**: `maxShardsPerNode` on CREATE, and the `/solr/admin/autoscaling` policy in `initialize_cloud.sh` / `policy.input.json`. Against a Solr 9 cluster these parameters are ignored or rejected; replica placement must be expressed with placement plugins instead. A `solr9` branch merge (`55dbac5`) is already in history, so treat the scripts as partially migrated.

## Collections referenced but not present

`delete.sh` and `initialize_cloud.sh` list `model_complex_role`, `model_compound`, `model_reaction`, `model_template_biomass`, and `model_template_reaction`, which have no configset directories here. Conversely, many newer collections (`bioset`, `bioset_result`, `epitope`, `epitope_assay`, `experiment`, `genome_typing`, `protein_feature`, `protein_structure`, `private_genome_metadata`, `sequence_feature`, `sequence_feature_vt`, `serology`, `spike_lineage`, `spike_variant`, `strain`, `surveillance`) exist as directories but are absent from the bulk scripts — create those with `create_one.sh`.

## Validating before you push

There is no linter. At minimum run an XML well-formedness check on anything you edit — a malformed schema fails at collection reload, not at commit time. `xmllint` is not installed on this host; use Python:

```bash
python3 -c "
import xml.dom.minidom, glob
for f in sorted(glob.glob('*/managed-schema')):
    try: xml.dom.minidom.parse(f)
    except Exception as e: print('BAD', f, e)"
```

Commit `aefe384` ("Syntax fixes for collection") exists because this step was skipped.
