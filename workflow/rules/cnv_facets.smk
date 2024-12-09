rule fair_cnv_facets_call:
    input:
        unpack(get_fair_cnv_facetts_call),
    output:
        vcf="CNV_bam.vcf.gz",
        cnv="genome_bam.cnv.png",
        hist="cnv_bam.hist.pdf",
        spider="qc_bam.spider.pdf",
    log:
        "logs/cnv_facets_bam.log",
    params:
        extra="",
    wrapper:
        "v5.2.1/bio/cnv_facets"