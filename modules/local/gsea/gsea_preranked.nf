
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process GSEA_PRERANKED {
    tag { meta.id }
    label 'process_single'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gsea:4.3.2--hdfd78af_0':
        'biocontainers/gsea:4.3.2--hdfd78af_0' }"

    input:
    tuple val (meta), path (rnk), path(gmt), val (minset), val (maxset), val (perm)

    output:
    tuple val(meta), path ("gsea_results")    , emit: gsea_path
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when


    script:
    def args = task.ext.args ?: ''
    VERSION = '4.3.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    #- GSEA default parameters listed in gsea_results/gsea.GseaPreranked.XXX/YYY.rpt
    gsea-cli GSEAPreranked \
        -rnk $rnk -gmx $gmt \
        -set_max $maxset -set_min $minset -nperm $perm \
        -out gsea_results

    gsea_folder=\$(find gsea_results -name "*GseaPreranked*" -type d)

    #- enrichment_zip does not do anything, but it is required for this to run
    gsea-cli LeadingEdgeTool \
        -enrichment_zip \$gsea_folder \
        -dir \$gsea_folder \
        -out gsea_results \
        -extraPlots TRUE

    # print to yml file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GSEA version: $VERSION
    END_VERSIONS
    """


}
