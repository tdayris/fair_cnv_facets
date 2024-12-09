        tumor="T.sample.bam",
        normal="N.sample.bam",
        vcf="common.sample.vcf.gz",


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