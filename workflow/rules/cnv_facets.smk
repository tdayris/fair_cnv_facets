rule fair_cnv_facets_call:
    input:
        unpack(get_fair_cnv_facetts_call),
    output:
        vcf="results/{species}.{build}.{release}.{datatype}/CNV/VCF/{sample}.vcf.gz",
        cnv="results/{species}.{build}.{release}.{datatype}/CNV/Graphs/{sample}.CNV.png",
        hist="results/{species}.{build}.{release}.{datatype}/CNV/Graphs{sample}.hist.pdf",
        spider="results/{species}.{build}.{release}.{datatype}/CNV/Graphs/{sample}.spider.pdf",
    threads: 20
    resources:
        mem_mb=lambda wildcards, attempt: attempt * 1_000,
        runtime=lambda wildcards, attempt: attempt * 60 * 5,
        tmpdir=tmp,
    log:
        "logs/fair_cnv_facets_call/{species}.{build}.{release}/{sample}.log",
    benchmark:
        "benchmark/fair_cnv_facets_call/{species}.{build}.{release}/{sample}.tsv",
    params:
        extra=lookup_config(dpath="params/fair_cnv_facets_call", default="",),
    wrapper:
        "v5.2.1/bio/cnv_facets"