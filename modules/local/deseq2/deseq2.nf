// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process DESEQ2 {
    label 'process_single'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-221100a52f7a6062a1dec9f34ce2a4ab4de1dffe:d02d387599ad4596922ae07c59c950502a89de66-0':
        'biocontainers/mulled-v2-221100a52f7a6062a1dec9f34ce2a4ab4de1dffe:d02d387599ad4596922ae07c59c950502a89de66-0' }"

    input:
    // TODO nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/nf-core/bwa/index/main.nf
    // TODO nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    path(inputdir)
    path(metadata)
    path(deseq2_conf)

    output:
    path "colData.tsv"        , emit: colData
    path "dds.rds"            , emit: dds
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'run_deseq2.R'

}

