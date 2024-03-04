
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process PLOT_FROM_GSEA_RESULTS {
    tag { meta.id }
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
    tuple val (meta), path (gsea_path), val (perm)

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

    #- Create the gsea_table

    prerankedfolder = list.files("$gsea_path", pattern="GseaPreranked")

    gsea_table <- data.frame("RANK"= character(),"GENESET"= character(),"GENESET_ORIGINAL_SIZE"= numeric(),
    "GENESET_SIZE_IN_DATA"= numeric(),"LEADING_EDGE_GENES"= numeric(),"RATIO"= numeric(),
    "RATIO_ORIGINAL_SIZE"= numeric(),"FDR_p"= numeric(),"NES"= numeric())

    originalsize <- read.table(paste0("$gsea_path", "/",prerankedfolder, "/gene_set_sizes.tsv"), sep="\t", header=T)

    for (type in c("pos","neg")) {
        posnegfile = list.files(paste0("$gsea_path","/",prerankedfolder), pattern=paste0("gsea_report_for_na_",type,"_.*.tsv"))
        posneg <- read.table(paste0("$gsea_path", "/",prerankedfolder, "/", posnegfile), sep="\t", header=T)
        posneg <- left_join(posneg, originalsize)
        for (i in c(1:length(rownames(posneg)))){
            if (file.exists(paste0("$gsea_path", "/",prerankedfolder,"/",posneg\$NAME[i], ".tsv"))){
                df <- read.table(paste0("$gsea_path", "/",prerankedfolder,"/",posneg\$NAME[i], ".tsv"), header=T, sep="\t")

                count=sum(df\$CORE.ENRICHMENT == "Yes")
                ratio=round(count/posneg\$SIZE[i], 2)
                ratiooriginal=round(count/posneg\$ORIGINAL.SIZE[i], 2)
                gsea_table <- rbind(gsea_table, data.frame("RANK"= "$meta.id","GENESET"= posneg\$NAME[i], "GENESET_ORIGINAL_SIZE"= posneg\$ORIGINAL.SIZE[i],
                            "GENESET_SIZE_IN_DATA"=posneg\$SIZE[i],"LEADING_EDGE_GENES"=count,"RATIO"= ratio,
                            "RATIO_ORIGINAL_SIZE"=ratiooriginal, "FDR_p"= posneg\$FDR.q.val[i],"NES"=posneg\$NES[i]))
            }
        }
    }

    #- Get range of NES for ylim
    rangeNES=round(max(abs(max(gsea_table\$NES)), abs(min(gsea_table\$NES)))+0.5)

    #- Replace FDR = 0 to FDR = 0.001 (as this was run on #perm iterations)
    gsea_table\$FDR_p[gsea_table\$FDR_p == 0] <- (1/$perm)

    #- get plot (based on code from https://www.biostars.org/p/168044/)
    png("gsea_plot.png", width=800)
    p <- ggplot(gsea_table, aes(NES, GENESET)) +
        geom_point(aes(colour=FDR_p, size=RATIO)) +
        geom_segment(mapping = aes(yend=GENESET, xend = 0), size=0.5, colour="gray50") +
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
