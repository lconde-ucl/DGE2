
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process GSEA_PRERANKED {
    tag { meta.id}
    label 'process_single'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
        'biocontainers/YOUR-TOOL-HERE' }"

    input:
    tuple val (meta), path (RNK), path(GMT), val (MINSET), val (MAXSET), val (PERM)

    output:
    tuple val(meta), path("gsea_table.txt")   , emit: gsea_table
    path "gsea_results"                       , emit: gsea_results
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    VERSION = '4.3.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    template "gsea_preranked.pl"

}
