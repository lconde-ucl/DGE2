<h1>
  DGE2
</h1>

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/dge)

## Introduction

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->


**DGE2** is a [nextflow](https://www.nextflow.io) pipeline built using code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) initative.
It is a differential gene expression analysis pipeline that is meant to be run after the data has been preprocessed with the
[nf-core/rnaseq](https://github.com/nf-core/rnaseq) pipeline (v3+) with default star_salmon alignment.


1. Takes salmon quantification files and a metadata file as input
2. Performs differential gene expression analysis over a specific design or if one is not specified, over all possible designs from the metadata file
3. Generates summary plots (PCA, volcano, heatmap) and txt files, as well as a summary HTML report
4. Runs gene set enrichment analysis on the preRanked list of genes from the DGE results


## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

<!-- TODO nf-core: Describe the minimum required steps to execute the pipeline, e.g. how to prepare samplesheets.
     Explain what rows and columns represent. For instance (please edit as appropriate):
-->

If you have run the [nf-core/rnaseq](https://github.com/nf-core/rnaseq) pipeline with default aligner (star/salmon), you should have a `results/star_salmon/` folder with several additional folders and files, including
a `quant.sf` file for each sample, plus a `tx2gene.tsv` file with the correspondence between transcript and gene identifiers:

```
results/star_salmon/SAMPLE_1/quant.sf
results/star_salmon/SAMPLE_2/quant.sf
results/star_salmon/SAMPLE_3/quant.sf
results/star_salmon/SAMPLE_4/quant.sf
results/star_salmon/SAMPLE_5/quant.sf
results/star_salmon/SAMPLE_6/quant.sf
results/star_salmon/tx2gene.tsv
[... other files and folders...]
```

In the above example, you would pass the `results/` folder to the DGE2 pipeline using the `--inputdir` argument

Additionally, you will need to prepare a `metadata.txt` file that looks as follows:

```
SampleID	Status	Levels
SAMPLE_1	ctr	high
SAMPLE_2	ctr	high
SAMPLE_3	ctr	med
SAMPLE_4	case	low
SAMPLE_5	case	low
SAMPLE_6	case	low
```

This should be a txt file where the first column are the sample IDs, and the other (1 or more) columns displays the conditions for each sample. The samples must match those in the `results/star_salmon` inputdir.

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run lconde-ucl/DGE2 \
   -profile <docker/singularity/.../institute> \
   --inputdir <PATH/TO/INPUTDIR/> \
   --metadata <PATH/TO/METADATA> \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://github.com/lconde-ucl/DGE2/blob/master/docs/usage.md)

## Pipeline output

The pipeline produces text files and plots with the DGE and GSEA results, as well as an HTML report that contains a summary of the DGE results.
For more details about the output files and reports, please refer to the
[output documentation](https://https://github.com/lconde-ucl/DGE2/blob/master/docs/output.md).


## Credits

DGE2 was developed by [Lucia Conde](https://https://github.com/lconde-ucl/) in 2024. This is a DSL2 version of an older (DSL1) [DGE pipeline](https://https://github.com/lconde-ucl/DGE) developed in 2019


## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

## Citations

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) initative, and reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> The nf-core framework for community-curated bioinformatics pipelines.
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> Nat Biotechnol. 2020 Feb 13. doi: 10.1038/s41587-020-0439-x.

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->
In addition, references of tools and data used in this pipeline are as follows:


