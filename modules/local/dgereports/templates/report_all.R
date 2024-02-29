#!/usr/bin/env Rscript


#----------------------------------
#- Load required packages
#----------------------------------
library(dplyr)
library(ini)
library(DESeq2)
library(ashr)
library(ggplot2)
library(ggrepel)
library(ComplexHeatmap)
library(ReportingTools)
library(png)
library(hwriter)


#--------------
#- Get data
#--------------
colData <- read.table("$COLDATA", sep="\\t",header=T, stringsAsFactors=TRUE)
dds<-readRDS("$DDS")

args<-read.ini("$DESEQCONF")

design = args\$deseq2\$DESIGN
condition = args\$deseq2\$CONDITION
treatment = args\$deseq2\$TREATMENT
control = args\$deseq2\$CONTROL
pval = as.numeric(args\$deseq2\$PVAL)
fc = as.numeric(args\$deseq2\$FC)


#---------
#- PCA
#----------
if(nrow(colData) < 30){
	transformation <- rlog(dds, blind=FALSE)
}else{
	transformation <- vst(dds, blind=FALSE)
}

pcaData<- plotPCA(transformation, intgroup=colnames(colData), returnData=TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))

pcaplot_name<-"PCAplot.png"
png(file=pcaplot_name)
if(ncol(colData)>1){
    ggplot(pcaData, aes(PC1, PC2, color=colData[,1], shape=colData[,2])) +
        geom_point(size=3) +
        scale_shape_manual(values=1:nlevels(colData[,2])) +
        ggtitle("PCA plot") +
        xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
        theme_classic() + theme(legend.position = "bottom", legend.title=element_blank())
}else{
    ggplot(pcaData, aes(PC1, PC2, color=colData[,1])) +
        geom_point(size=3) +
        ggtitle("PCA plot") +
        xlab(paste0("PC1: ",percentVar[1],"% variance")) +
        ylab(paste0("PC2: ",percentVar[2],"% variance")) +
        theme_classic() + theme(legend.position = "bottom", legend.title=element_blank())
}
dev.off()


#-----------------------------------------------------------------------
#- Modify one of the functions in ReportingTools so that the norm count
#- 	plots per gene are in different folders for each contrast
#-	so that plots for a gene that come up in 2 analyses are not overwritten
#- modified from https://rdrr.io/bioc/ReportingTools/src/R/addReportColumns-methods.R
#-----------------------------------------------------------------------
setMethod("modifyReportDF",
    signature = signature(object = "DESeqResults"),
        definition = function(df, htmlRep, object, DataSet, factor, make.plots = TRUE, contrast, ...){
            if("EntrezId" %in% colnames(df)){
                df <- entrezGene.link(df)
            }
            if(make.plots){
                dots <- list(...)
                par.settings <- list()
                if("par.settings" %in% names(dots))
                    par.settings <- dots\$par.settings

                figure.dirname <- paste("figures/",contrast, sep='')
                figure.directory <- file.path(dirname(path(htmlRep)),
                                            figure.dirname)
                dir.create(figure.directory, recursive = TRUE)

                df <- ReportingTools:::eSetPlot(df, DataSet, factor, figure.directory,
                    figure.dirname, par.settings = par.settings,
                    ylab.type = "Normalized Counts")
                df
            }
            df
        }
)


#-------------------------------------------------------------
#- Get results using default design and all possible contrasts
#-------------------------------------------------------------
reportdirALL="DGE2_report"
title=paste0('RNA-seq DGE analysis using DESeq2 with default (no design specified) mode')
des2ReportALL <- HTMLReport(shortName = 'DGE2', title = title, reportDirectory = reportdirALL)

himg <- hwriteImage(paste0("../DGE2_PlotsAndFiles/",pcaplot_name))
publish(hwrite(himg, br=TRUE,center=TRUE), des2ReportALL)
n=1
for (i in 1:ncol(colData)) {
    pairs<-combn(unique(colData[,i]),2)
    for (j in 1:ncol(pairs)) {

        #- alpha is fdr threshold for summary display only
        res<-results(dds, contrast = c(colnames(colData)[i],as.character(pairs[,j])), alpha=0.05)
        resNorm <- lfcShrink(dds, contrast = c(colnames(colData)[i],as.character(pairs[,j])), res=res, type="ashr")

        #-----------------------
        #- File with all results
        #-----------------------
        contrastname = paste0(colnames(colData)[i], "_", paste0(as.character(pairs[,j]),collapse="_vs_"))
        write.table(resNorm, file=paste0(contrastname, "_results.txt"), sep="\\t",quote=F,row.names=T, col.names=NA)

        #-----------------------
        #- Heatmap plot
        #-----------------------

        heatmap_name<-paste0(contrastname, "_heatmap.png")

        de <- rownames(resNorm[resNorm\$padj<0.05 & !is.na(resNorm\$padj) & abs(resNorm\$log2FoldChange) > fc, ])

        if(length(de) < 5) {
            message<-paste0("Only ", length(de), " genes with Padj<0.05 and Log2FC>",fc,".\\n\\nPlease rerun the pipeline with a\\nlower FC threshold to generate a heatmap")

            png(file=heatmap_name, width=600, height=600, res=200)
            plot(0, type = 'n', axes = FALSE, ann = FALSE)
            mtext(message, side = 3, cex=0.5)
            dev.off()

        }else{

            de_mat <- assay(transformation)[de,]

            png(file=heatmap_name, width=1500, height=2000, res=200)

            ha<-HeatmapAnnotation(df = select(colData, !!colnames(colData)[i]))
            p <- Heatmap(t(scale(t(de_mat))),
                name = "Normalized counts (scaled)",
                row_names_gp = gpar(fontsize = 6),column_names_gp = gpar(fontsize = 4),
                heatmap_legend_param = list(legend_direction = "horizontal"),
                show_column_names = TRUE,
                top_annotation = ha,
                show_row_names = TRUE,
                cluster_columns = TRUE,
                column_names_side = "top")
            print(p)
            dev.off()
        }

        #-----------------------
        #- MA plot
        #-----------------------
        maplot_name<-paste0(contrastname, "_MAplot.png")
        png(file=maplot_name)
        maplot <- plotMA(resNorm, ylim=c(-5,5))
        dev.off()

        #------------------------
        #- Volcano plot
        #------------------------

        vplot_name<-paste0(contrastname, "_VolcanoPlot.png")

        ha<-data.frame(gene = rownames(resNorm), logFC = resNorm\$log2FoldChange, Pval = resNorm\$pvalue)
        ha = within(ha, {Col="Other"})
        ha[abs(ha\$logFC) > fc, "Col"] <- paste0("|logFC| > ",fc)
        ha[!is.na(ha\$Pval) & ha\$Pval <pval, "Col"] <- paste0("Pval < ",pval)
        ha[!is.na(ha\$Pval) & ha\$Pval <pval & abs(ha\$logFC)>fc, "Col"] <- paste0("Pval < ",pval, " & |logFC| > ", fc)
        ha\$Col<-factor(ha\$Col, levels=c(paste0("Pval < ",pval),paste0("|logFC| > ",fc),paste0("Pval < ",pval, " & |logFC| > ", fc), "Other"), labels=c(paste0("Pval < ",pval),paste0("|logFC| > ",fc),paste0("Pval < ",pval, " & |logFC| > ", fc), "Other"))

        png(file=vplot_name)
        p<-ggplot(ha, aes(logFC,  -log10(Pval))) +
        geom_point(aes(col=Col), alpha=0.5) +
        ggtitle(contrastname) +
        geom_hline(yintercept = -log10(pval), linetype = 2, alpha = 0.5) +
        geom_vline(xintercept = fc, linetype = 2, alpha = 0.5) +
        geom_vline(xintercept = -fc, linetype = 2, alpha = 0.5) +
        scale_color_manual(values=c("indianred1", "gold2", "cornflowerblue", "gray47")) +
        theme_classic() + theme(legend.position = "bottom", legend.title=element_blank())

        #- add gene labels for genes with pval anf fc below theresholds
        ha2 <- ha %>%
            filter(Pval < pval & (logFC >= fc | logFC <= -fc)) %>%
            select(gene,logFC,Pval, Col)

        p<-p+geom_text_repel(data=ha2,aes(label=gene), box.padding = unit(0.35, "lines"), point.padding = unit(0.3, "lines"), force=10, size=3,segment.size=0.25,segment.alpha=0.5)
        print(p)
        dev.off()

        #-----------------------
        #- Report
        #-----------------------

        allplot_name<-paste0(contrastname, "_MAandVolcano.png")
        img1 <- readPNG(maplot_name)
        img2 <- readPNG(vplot_name)
        png(file=allplot_name, width=1200, height=600)
        par(mai=rep(0,4)) # no margins
        layout(matrix(1:2, ncol=2, byrow=TRUE))
        for(l in 1:2) {
            plot(NA,xlim=0:1,ylim=0:1,bty="n",axes=0,xaxs = 'i',yaxs='i')
            rasterImage(eval(parse(text=paste0("img", l))),0,0,1,1)
        }
            dev.off()

        publish(paste0("<center><h3><u>Contrast ", n, ":</u>  ", contrastname), des2ReportALL)
        publish("<h4>MA/Volcano plots", des2ReportALL)
        himg <- hwriteImage(paste0("../DGE2_PlotsAndFiles/",contrastname, "/",allplot_name))
        publish(hwrite(himg, br=TRUE,center=TRUE), des2ReportALL)
        publish("<h4>Top 100 differentially expressed genes", des2ReportALL)
        publish(resNorm,des2ReportALL, contrast = contrastname, pvalueCutoff=1, n=100, DataSet=dds, factor=colData(dds)[[i]])
        publish(paste0("<h4>Heatmap DE genes (FDR 0.05, |log2FC| ",fc,")"), des2ReportALL)
        himg <- hwriteImage(paste0("../DGE2_PlotsAndFiles/",contrastname, "/",heatmap_name))
        publish(hwrite(himg, br=TRUE,center=TRUE), des2ReportALL)
        n=n+1
    }
}
finish(des2ReportALL)



#---------------
#- Save versions
#---------------
version <- R.Version()
deseq2.version <- as.character(packageVersion('DESeq2'))
complexheatmap.version <- as.character(packageVersion('ComplexHeatmap'))
ashr.version <- as.character(packageVersion('ashr'))
ggplot2.version <- as.character(packageVersion('ggplot2'))
ReportingTools.version <- as.character(packageVersion('ReportingTools'))
hwriter.version <- as.character(packageVersion('hwriter'))

# print to yml file
writeLines(c(
    "REPORT_ALL:",
    paste0("  r_version: '", version\$version, "'"),
    paste0("  DESeq2 version: '", deseq2.version, "'"),
    paste0("  ashr version: '", ashr.version, "'"),
    paste0("  ComplexHeatmap version: '", complexheatmap.version, "'"),
    paste0("  ggplot2 version: '", ggplot2.version, "'"),
    paste0("  ReportingTools version: '", ReportingTools.version, "'"),
    paste0("  hwriter version: '", hwriter.version, "'")
), con = "versions.yml")

