#!/usr/bin/env Rscript


#----------------------------------
#- Load required packages
#- (all of them are available in bioconda/R)
#----------------------------------
library("ini")
library("DESeq2")
library("tximport")


#------------
#- Parse args
#------------

args<-read.ini("deseq2.conf")

inputdir = args\$deseq2\$INPUTDIR
metadata = args\$deseq2\$METADATA
design = args\$deseq2\$DESIGN
condition = args\$deseq2\$CONDITION
treatment = args\$deseq2\$TREATMENT
control = args\$deseq2\$CONTROL


#--------------
#- Get metadata
#--------------
colData <- read.table(metadata, sep="\t",header=T, stringsAsFactors=TRUE)
samples<-colData[,1]
colnames<-colnames(colData)
colData<-as.data.frame(colData[,-c(1)])
rownames(colData)<-samples
colnames(colData)<-colnames[-1]

write.table(colData, file="colData.tsv", sep="\t", quote=FALSE, row.names=TRUE)

#-------------------------------
#- Specify design and contrast
#-------------------------------
default="no"
if(design == 'null'){
	design = paste0(colnames(colData)[1:ncol(colData)], collapse=" + ")
	default="yes"
}else{
    if(!(condition %in% colnames(colData))) {
        stop("ERROR: condition '",condition,"' is not a column of the metadata file, please specify a valid condition")
    }
    if(!(treatment %in% levels(colData[colnames(colData) == condition][,1]))) {
        stop("ERROR: treatment '",treatment,"' is not a level in condition ",condition,". Please specify a valid treatment")
    }
    if(!(control %in% levels(colData[colnames(colData) == condition][,1]))) {
        stop("ERROR: control '",control,"' is not a level in condition ",condition,". Please specify a valid control")
    }
}

#-----------------------------------------------------------------------
#- Get counts and create dds
#- Make sure that first column has the sample names, that these samples
#-  are all in countData, and that they are in the same order, and that
#-  the tx2gene file exists
#-----------------------------------------------------------------------

#- tx2gene file
tx2gene.file <- file.path(inputdir, "star_salmon/tx2gene.tsv")
if (!file.exists(tx2gene.file)){
    stop("ERROR: ", tx2gene.file, " cannot be found. Please check that this file exists, it should have been created when running the nf-core/rnaseq pipeline.")
}
tx2gene<-read.table(tx2gene.file, header=T, sep="\t")
colnames(tx2gene)<-c("transcript", "gene", "gene2")

#- read counts
files <- file.path(inputdir, "star_salmon", rownames(colData), "quant.sf")
names(files)<-basename(dirname(files))
if(length(rownames(colData)[!rownames(colData) %in% names(files)]) > 0) {
    stop("ERROR: the following samples don't have a salmon quant.sf file: ", paste(rownames(colData)[!rownames(colData) %in% names(files)], collapse=", "),
        ". Please make sure that the first column of your metadata file has the sample IDs.")
}

#- check that the samples from salmon and the samples from the metadata are the same and in the same order
txi <- tximport(files, type = "salmon", tx2gene=tx2gene)
countData<-txi\$counts
countData = countData[ , rownames(colData) ] #- this is not really necessary as this should already be sorted properly
if(!all(rownames(colData) == colnames(countData))) {
    stop("ERROR: Something is wrong, this should never happen [rownames(colData) ne colnames(countData)??]")
}

#- create dds
dds <- DESeqDataSetFromTximport(txi=txi,
        colData=colData,
        design=eval(parse(text=paste0("~ ", design))))

#-------------------------------------------
#- remove genes with <= 5 counts in all samples
#-------------------------------------------
dds <- dds[ rowSums(counts(dds)) > 5, ]

#---------
#- Run DGE
#----------
dds <- DESeq(dds)
saveRDS(dds, file = "dds.rds")

#---------------
#- Save versions
#---------------
version <- R.Version()
deseq2.version <- as.character(packageVersion('DESeq2'))

# print to yml file
writeLines(c(
    "DESEQ2:",
    paste0("  deseq2 version: '", deseq2.version, "'"),
    paste0("  r_version: '", version\$version, "'")
), con = "versions.yml")



