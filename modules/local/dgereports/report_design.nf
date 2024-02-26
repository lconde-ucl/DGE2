
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process REPORT_DESIGN {
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
    path(DDS)
    path(COLDATA)
    path(DESEQCONF)

    output:
    path "*_results.txt"                                                    , emit: resNorm
    path "*{_MAplot.png,_VolcanoPlot.png,_heatmap.png,_MAandVolcano.png}"   , emit: pngs
    path "PCAplot.png"                                                      , emit: pcaplot
    path "DGE2_report"                                                      , emit: report
    path "versions.yml"                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    template 'report_design.R'

}
