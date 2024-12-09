import csv
import os
import pandas
import snakemake
import snakemake.utils

from typing import Any, NamedTuple


snakemake_min_version: str = "8.14.0"
snakemake.utils.min_version(snakemake_min_version)

snakemake_docker_image: str = "docker://snakemake/snakemake:v8.16.0"


container: snakemake_docker_image


# Load and check configuration file
default_config_file: str = "config/config.yaml"


configfile: default_config_file


snakemake.utils.validate(config, "../schemas/config.schema.yaml")


# Load and check samples properties table
def load_table(path: str) -> pandas.DataFrame:
    """
    Load a table in memory, automatically inferring column separators

    Parameters:
    path (str): Path to the table to be loaded

    Return
    (pandas.DataFrame): The loaded table
    """
    with open(path, "r") as table_stream:
        dialect: csv.Dialect = csv.Sniffer().sniff(table_stream.readline())
        table_stream.seek(0)

    # Load table
    table: pandas.DataFrame = pandas.read_csv(
        path,
        sep=dialect.delimiter,
        header=0,
        index_col=None,
        comment="#",
        dtype=str,
    )

    # Remove empty lines
    table = table.where(table.notnull(), None)

    return table


def load_genomes(
    path: str | None = None, samples: pandas.DataFrame | None = None
) -> pandas.DataFrame:
    """
    Load genome file, build it if genome file is missing and samples is not None.

    Parameters:
    path    (str)               : Path to genome file
    samples (pandas.DataFrame)  : Loaded samples
    """
    if path is not None:
        genomes: pandas.DataFrame = load_table(path)

        if samples is not None:
            genomes = used_genomes(genomes, samples)
        return genomes

    elif samples is not None:
        return samples[["species", "build", "release"]].drop_duplicates(
            ignore_index=True
        )

    raise ValueError(
        "Provide either a path to a genome file, or a loaded samples table"
    )


def used_genomes(
    genomes: pandas.DataFrame, samples: pandas.DataFrame | None = None
) -> tuple[str]:
    """
    Reduce the number of genomes to download to the strict minimum
    """
    if samples is None:
        return genomes

    return genomes.loc[
        genomes.species.isin(samples.species.tolist())
        & genomes.build.isin(samples.build.tolist())
        & genomes.release.isin(samples.release.tolist())
    ]


# Load and check samples properties tables
try:
    if (samples is None) or samples.empty():
        sample_table_path: str = config.get("samples", "config/samples.csv")
        samples: pandas.DataFrame = load_table(sample_table_path)
except NameError:
    sample_table_path: str = config.get("samples", "config/samples.csv")
    samples: pandas.DataFrame = load_table(sample_table_path)

snakemake.utils.validate(samples, "../schemas/samples.schema.yaml")


# Load and check genomes properties table
genomes_table_path: str = config.get("genomes", "config/genomes.csv")
try:
    if (genomes is None) or genomes.empty:
        genomes: pandas.DataFrame = load_genomes(genomes_table_path, samples)
except NameError:
    genomes: pandas.DataFrame = load_genomes(genomes_table_path, samples)

snakemake.utils.validate(genomes, "../schemas/genomes.schema.yaml")


report: "../report/workflows.rst"


snakemake_wrappers_prefix: str = config.get("snakemake_wrappers_prefix", "v3.13.7")
release_tuple: tuple[str] = tuple(set(genomes.release.tolist()))
build_tuple: tuple[str] = tuple(set(genomes.build.tolist()))
species_tuple: tuple[str] = tuple(set(genomes.species.tolist()))
datatype_tuple: tuple[str] = ("dna", "cdna", "all", "transcripts")
gxf_tuple: tuple[str] = ("gtf", "gff3")
id2name_tuple: tuple[str] = ("t2g", "id_to_gene")
tmp: str = f"{os.getcwd()}/tmp"
samples_id_tuple: tuple[str] = tuple(samples.sample_id)
stream_tuple: tuple[str] = ("1", "2")


wildcard_constraints:
    sample=r"|".join(samples_id_tuple),
    release=r"|".join(release_tuple),
    build=r"|".join(build_tuple),
    species=r"|".join(species_tuple),
    datatype=r"|".join(datatype_tuple),
    stream=r"|".join(stream_tuple),
    gxf=r"|".join(gxf_tuple),
    id2name=r"|".join(id2name_tuple),


def lookup_config(
    dpath: str, default: str | None = None, config: dict[str, Any] = config
) -> str:
    """
    Run lookup function with default parameters in order to search a key in configuration and return a default value
    """
    value: str | None = default

    try:
        value = lookup(dpath=dpath, within=config)
    except LookupError:
        value = default
    except WorkflowError:
        value = default

    return value


def lookup_genomes(
    wildcards: snakemake.io.Wildcards,
    key: str,
    default: str | list[str] | None = None,
    genomes: pandas.DataFrame = genomes,
) -> str:
    """
    Run lookup function with default parameters in order to search user-provided sequence/annotation files
    """
    query: str = "species == '{wildcards.species}' & build == '{wildcards.build}' & release == '{wildcards.release}'".format(
        wildcards=wildcards
    )

    query_result: str | float = getattr(
        lookup(query=query, within=genomes), key, default
    )
    if (query_result != query_result) or (query_result is None):
        # Then the result of the query is nan
        return default
    return query_result




def get_normal_sample(
    wildcards: snakemake.io.Wildcards, samples: pandas.DataFrame = samples
) -> str | None:
    """
    Return corresponding Normal sample (if any)
    """
    query: str = "species == '{wildcards.species}' & build == '{wildcards.build}' & release == '{wildcards.release}' & sample_id == '{wildcards.sample}'".format(
        wildcards=wildcards
    )
    sample_query: NamedTuple = lookup(query=query, within=samples)
    return getattr(sample_query, "normal_sample_id", None)


def get_normal_bam(
    wildcards: snakemake.io.Wildcards, samples: pandas.DataFrame = samples
) -> str | None:
    """
    Return corresponding Normal bam file (if any)
    """
    normal_id: str | None = get_normal_sample(wildcards, samples)
    if normal_id:
        return "tmp/fair_gatk_mutect2_picard_reaplace_read_groups/{wildcards.species}.{wildcards.build}.{wildcards.release}.{wildcards.datatype}/{normal_id}.bam".format(
            wildcards=wildcards, normal_id=normal_id
        )


def get_fair_cnv_facetts_call(
    wildcards: snakemake.io.Wildcards, 
    samples: pandas.DataFrame = samples,
) -> dict[str, str]:
    """
    Return files required by CNV Facets
    """
    cnv_facets_inputs = {
        "tumor": f"results/{wildcards.species}.{wildcards.build}.{wildcards.release}.{wildcards.datatype}/Mapping/{wildcards.sample}.bam",
    }

    normal_bam: str | None = get_normal_bam(wildcards)
    if not normal_bam:
        raise ValueError(f"Cannot run CNV_Facets, no normal given for {wildcards.sample}")

    cnv_facets_inputs["normal"] = normal_bam
    cnv_facets_inputs["tumor_bai"] = cnv_facets_bam["tumor"] + ".bai"
    cnv_facets_inputs["normal_bai"] = cnv_facets_bam["normal"] + ".bai"

    return cnv_facets_inputs