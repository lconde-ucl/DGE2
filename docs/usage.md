# DGE2: Usage



## Introduction

<!-- TODO nf-core: Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website. -->

## Mandatory input/output arguments

### `--inputdir DIR`

This is used to specify the location of the results folder obtained after running the [nfcore rnaseq](https://github.com/nf-core/rnaseq) pipeline (v3+).
The DGE2 pipeline assumes that the `[inputdir]` folder contains a `[inputdir]/star_salmon/` folder with the following structure:

```
results/star_salmon/SAMPLE_1/quant.sf
results/star_salmon/SAMPLE_2/quant.sf
results/star_salmon/SAMPLE_3/quant.sf
results/star_salmon/SAMPLE_4/quant.sf
results/star_salmon/SAMPLE_5/quant.sf
results/star_salmon/SAMPLE_6/quant.sf
results/star_salmon/tx2gene.tsv
[...]
```

There you should have a `quant.sf` file for each sample, plus a `tx2gene.tsv` file with the correspondence between transcript and gene identifiers.

> Please note that running the nextflow_rnaseq pipeline is not mandatory- As long as you have an `[inputdir]/star_salmon/` folder with the salmon abundance files and tx2gene file, you can run the DGE2 pipeline; just organize the files in a folder structure like the above.


### `--metadata FILE`

Additionally, you will need to prepare a metadata file that looks as follows:

```
SampleID	Status	Levels
SAMPLE_1	ctr high
SAMPLE_2	ctr	high
SAMPLE_3	ctr	med
SAMPLE_4	case	low
SAMPLE_5	case	low
SAMPLE_6	case	low
```

This should be a txt file where the first column are the sample IDs, and the other (1 or more) columns displays the conditions for each sample. The samples must match those in the `results/star_salmon` inputdir.


### `--outdir DIR`

Name of the output folder.


## DESeq2 arguments

If the desired model is not specified, the DGE pipeline will run differential gene expression analysis using a multi-factor design encompasing all the variables from the metadata file ( ~ CONDITION1 + CONDITION2 +...). The pipeline will generate results for every variable in the design. For example, for the `metadata.txt` file above, the pipeline will run the following analysis:

```
Design: ~ Status + Levels
Contrasts:
	cases vs. controls (status)
	high vs. medium (levels)
	high vs. low (levels)
	medium vs. low (levels)
```

Please note that the order of the variables in the design is taken from the order of the variable in the metadata file. This default approach may not be especially useful or relevant for the user's specific needs, particularly if the metadata file containes variables that are not of interest. Therefore, it is recommended that users **explicitly define the relevant design and comparisons of interest for their experiment**, by specifying the following arguments:


### `--design STR`
Specifies DESeq2 design. If defined, --condition, --treatment and --control must also be defined.
Not used by default.

### `--condition STR`
Specifies 'condition' for the DESeq2 contrast. Requires --design to be specified.
Not used by default.

### `--treatment STR`
Specifies 'treatment' for the DESeq2 contrast. Requires --design to be specified.
Not used by default.

### `--control STR`
Specifies 'control' for the DESeq2 contrast. Requires --design to be specified.
Not used by default.


## GSEA arguments

For each comparison above, a GSEA analysis using the hallmark gene sets from MSigDB will be performed.

> Please note that the hallmark dataset contains HUGO IDs. If your tx2gene file has different gene IDs (it will depend on what assembly/GFT file you used when you ran the nf-core/rnaseq pipeline), or if your data are from a species other than human, the default hallmark
gene set will not work with your data. You will have to either skip GSEA with the --skip_gsea flag, or add an appropiate gene set with the --gmx argument.

### `--skip_gsea`
Skip GSEA step, otherwise it will run GSEA on each result file.
Not used by default.

### `--gmx STR`
File with gene sets in GMX format. If not specified, it will use the hallmark gene sets from MSigDB (human HUGO IDs).

### `--min_set NUM`
Ignore gene sets that contain less than NUM genes.
Default = 15

### `--max_set NUM`
Ignore gene sets that contain more than NUM genes.
Default = 500

### `--perm NUM`
Number of permutations for the NES calculation.
Default = 1000


## Volcano plot arguments

One of the plots produced from the differential gene expression analysis is a volcano plot. Here you can control the gene labels shown in the plot by modifying the P-val and FC thresholds i the plot.

### `--pval NUM`
Pval threshold to display gene labels in the output volcano plot.
Default:  1e-50

### `--fc NUM`
FC threshold to display gene labels in the output volcano plot.
Default: 3


## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run lconde-ucl/DGE2 \
  --inputdir ./results_rnaseq \
  --metadata ./metadata.txt \
  --outdir result_dge \
  -profile singularity
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

You can choose a specific `design` and contrast using the arguments mentioned above. E.g., if you want to run differential expression of cases versus controls (Status column), without adjusting for any other variable, you will run:

```
nextflow run lconde-ucl/DGE2 \
  --inputdir ./results_rnaseq \
  --metadata ./metadata.txt \
  --design Status \
  --condition Status \
  --treatment case \
  --control ctr \
  --outdir result_dge \
  -profile singularity
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify any of these in a params file. Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run lconde-ucl/DGE2 \
  -profile singularity \
  -params-file params.yaml
```

with `params.yaml` containing:

```yaml
inputdir: 'results_rnaseq'
metadata: 'metadata.txt'
outdir: 'result_dge'
design: 'Status'
condition: 'Status'
treatment: 'case'
control: 'ctr'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull lconde-ucl/DGE2
```

### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [lconde-ucl/DGE2 releases page](https://github.com/lconde-ucl/DGE2/releases) and find the latest pipeline version - numeric only (eg. `1.0`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.0`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.



### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Azure Resource Requests

To be used with the `azurebatch` profile by specifying the `-profile azurebatch`.
We recommend providing a compute `params.vm_type` of `Standard_D16_v3` VMs by default but these options can be changed if required.

Note that the choice of VM size depends on your quota and the overall workload during the analysis.
For a thorough list, please refer the [Azure Sizes for virtual machines in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
