[![Snakemake](https://img.shields.io/badge/snakemake-≥7.29.0-brightgreen.svg)](https://snakemake.github.io)
[![GitHub actions status](https://github.com/tdayris/fair_cnv_facets/workflows/Tests/badge.svg)](https://github.com/tdayris/fair_cnv_facets/actions?query=branch%3Amain+workflow%3ATests)

Do not use. Active dev.

Snakemake workflow used to call somatic CNV with Facets

## Usage

The usage of this workflow is described in the [Snakemake workflow catalog](https://snakemake.github.io/snakemake-workflow-catalog?usage=tdayris/fair_cnv_facets) 
it is also available [locally](https://github.com/tdayris/fair_cnv_facets/blob/main/workflow/report/usage.rst) on a single page.
 
## Results

A complete description of the results can be found here in [workflow reports](https://github.com/tdayris/fair_cnv_facets/blob/main/workflow/report/results.rst).

## Material and Methods

The tools used in this pipeline are described [here](https://github.com/tdayris/fair_cnv_facets/blob/main/workflow/report/material_methods.rst) textually. Web-links are available below:

![workflow_rulegraph](dag.png)

### Index and genome sequences with [`fair_genome_indexer`](https://github.com/tdayris/fair_genome_indexer/tree/main)

#### Get DNA sequences

| Step                             | Commands                                                                                                         |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Download DNA Fasta from Ensembl  | [ensembl-sequence](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/reference/ensembl-sequence.html) |
| Remove non-canonical chromosomes | [pyfaidx](https://github.com/mdshw5/pyfaidx)                                                                     |
| Index DNA sequence               | [samtools](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/samtools/faidx.html)                     |
| Creatse sequence Dictionary      | [picard](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/picard/createsequencedictionary.html)      |

#### Get genome annotation (GTF)

| Step                                                       | Commands                                                                                                             |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Download GTF annotation                                    | [ensembl-annotation](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/reference/ensembl-annotation.html) |
| Fix format errors                                          | [Agat](https://agat.readthedocs.io/en/latest/tools/agat_convert_sp_gff2gtf.html)                                     |
| Remove non-canonical chromosomes, based on above DNA Fasta | [Agat](https://agat.readthedocs.io/en/latest/tools/agat_sq_filter_feature_from_fasta.html)                           |
| Remove `<NA>` Transcript support levels                    | [Agat](https://agat.readthedocs.io/en/latest/tools/agat_sp_filter_feature_by_attribute_value.html)                   |

#### Get dbSNP variants

| Step                             | Commands                                                                                                                                     |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Download dbSNP variants          | [ensembl-variation](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/reference/ensembl-variation.html)                           |
| Filter non-canonical chromosomes | [pyfaidx](https://github.com/mdshw5/pyfaidx) + [BCFTools](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/bcftools/filter.html) |
| Index variants                   | [tabix](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/tabix/index.html)                                                       |

### Bowtie2 Mapping with [`fair_bowtie2_mapping`](https://github.com/tdayris/fair_bowtie2_mapping/tree/main)

#### Align reads over the genome

| Step             | Meta-Wrapper                                                                                                             | Wrapper                                                                                                                          |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| Bowtie2-build    | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [bowtie2-build](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/bowtie2/build.html)                                 |
| Fastp            |                                                                                                                          | [fastp](https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/fastp.html)                                                 |
| Bowtie2-align    | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [bowtie2-align](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/bowtie2/align.html)                                 |
| Sambamba sort    | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [sambamba-sort](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/sambamba/sort.html)                                 |
| Sambamba-view    | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [sambamba-view](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/sambamba/view.html)                                 |
| Sambamba-markdup | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [sambamba-markdup](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/sambamba/markdup.html)                           |
| Sambamba-index   | [bowtie2-sambamba meta-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/meta-wrappers/bowtie2_sambamba.html) | [sambamba-index](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/sambamba/index.html)                               |

#### Quality controls

| Step     | Wrapper                                                                                                                          |
| -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Picard   | [picard-collectmultiplemetrics](https://snakemake-wrappers.readthedocs.io/en/stable/wrappers/picard/collectmultiplemetrics.html) |
| Samtools | [samtools-stats](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/samtools/stats.html)                               |
| FastQC   | [fastqc-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/fastqc.html)                                       |
| MultiQC  | [multiqc-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/multiqc.html)                                     |


### Call CNV with Facets

| Step     | Wrapper                                                                                    |
| -------- | ------------------------------------------------------------------------------------------ |
| Facets   | [cnv_facets](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/cnv_facets.html) |

#### Quality controls

| Step               | Wrapper                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| MultiQC            | [multiqc-wrapper](https://snakemake-wrappers.readthedocs.io/en/v3.3.6/wrappers/multiqc.html)       |