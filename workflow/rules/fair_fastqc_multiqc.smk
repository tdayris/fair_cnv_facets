module fair_fastqc_multiqc:
    snakefile:
        config.get(
            "fair_fastqc_multiqc",
            github(
                "tdayris/fair_fastqc_multiqc",
                path="workflow/Snakefile",
                tag="2.4.2",
            ),
        )
    config:
        {**config, "load_fair_genome_indexer": False}


use rule * from fair_fastqc_multiqc
