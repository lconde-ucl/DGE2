
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process PLOT_GSEA {
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
    tuple val (meta), path (gsea_table), val (perm)

    output:
    tuple val(meta), path("gsea_plot.png")   , emit: gsea_table
    path "versions.yml"                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env Rscript

    library(ggplot2)
    library(dplyr)

    data<-read.table("$gsea_table", sep="\\t", header=T)

    #- Get range of NES for ylim
    rangeNES=round(max(abs(max(data\$NES)), abs(min(data\$NES)))+0.5)

    #- Replace FDR = 0 to FDR = 0.001 (as this was run on 1000 iterations)
    data\$FDR_p[data\$FDR_p == 0] <- (1/$perm)

    #- THIS WORKED IN PREVIOUS VERSIONS OF R, NOT NOW
    ##- Add numeric variable for GENESET to be able to draw horizontal lines
    #data <- transform(data, GENESET0 = as.numeric(GENESET))
    data <- mutate(data, GENESET0 = GENESET)

    #- get plot (based on code from https://www.biostars.org/p/168044/)
    png("gsea_plot.png", width=800)
    p <- ggplot(data, aes(NES, GENESET)) +
        geom_point(aes(colour=FDR_p, size=RATIO)) +
        geom_segment(mapping = aes(yend=GENESET0, xend = 0), size=0.5, colour="gray50") +
        geom_point(aes(colour=FDR_p, size=RATIO)) +
        scale_color_gradient(limits=c(0, 0.05), low="red", high="white") +
        geom_vline(xintercept=0, size=0.5, colour="gray50") +
        theme(strip.text.x = element_text(size = 8),
        panel.background=element_rect(fill="gray95", colour="gray95"),
            panel.grid.major=element_line(size=0.25,linetype='solid', colour="gray90"),
            panel.grid.minor=element_line(size=0.25,linetype='solid', colour="gray90"),
            axis.title.y=element_blank()) +
        expand_limits(x=c(-rangeNES,rangeNES)) +
        scale_x_continuous(breaks=seq(-rangeNES, rangeNES, 2)) +
        facet_grid(.~RANK)
    print(p)
    dev.off()

    #---------------
    #- Save versions
    #---------------
    version <- R.Version()
    ggplot2.version <- as.character(packageVersion('ggplot2'))
    dplyr.version <- as.character(packageVersion('dplyr'))

    # print to yml file
    writeLines(c(
        "PLOT_GSEA:",
        paste0("  r_version: '", version\$version, "'"),
        paste0("  ggplot2 version: '", ggplot2.version, "'"),
        paste0("  dplyr version: '", dplyr.version, "'")

    ), con = "versions.yml")

    """

}
