/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowDge.initialise(params, log)

// Check mandatory arguments
if( params.inputdir ){
    ch_inputdir = Channel.fromPath(params.inputdir, checkIfExists: true)
} else {
    error("No inputdir specified! Specify path with --inputdir.")
}
if( params.metadata ){
    ch_metadata = Channel.fromPath(params.metadata, checkIfExists: true)
} else {
    error("No metadata specified! Specify path with --metadata.")
}

// Check optional parameters
if ((params.design) && (!params.condition || !params.treatment || !params.control)){
    error("Invalid arguments: --design \'${params.design}\' requires --condition, --treatment and --control. Please specify all of them or run the pipeline without specifying any design")
}
if ((params.condition) && (!params.design || !params.treatment || !params.control)){
    error("Invalid arguments: --condition \'${params.condition}\' requires --design, --treatment and --control. Please specify all of them or run the pipeline without specifying any design")
}
if ((params.treatment) && (!params.design || !params.condition || !params.control)){
    error("Invalid arguments: --treatment \'${params.treatment}\' requires --design, --condition and --control. Please specify all of them or run the pipeline without specifying any design")
}
if ((params.control) && (!params.design || !params.treatment || !params.condition)){
    error("Invalid arguments: --control \'${params.control}\' requires --design, --condition and --treatment. Please specify all of them or run the pipeline without specifying any design")
}

ch_design = Channel.of(params.design)
ch_condition = Channel.of(params.condition)
ch_treatment = Channel.of(params.treatment)
ch_control = Channel.of(params.control)

ch_gmt = Channel.fromPath(params.gmt, checkIfExists: true)

ch_minset = Channel.of(params.min_set)
ch_maxset = Channel.of(params.max_set)
ch_perm = Channel.of(params.perm)
ch_pval = Channel.of(params.pval)
ch_fc = Channel.of(params.fc)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { CREATE_PARAM_FILE      } from '../modules/local/create_param_file'
include { DESEQ2                 } from '../modules/local/deseq2/deseq2'
include { REPORT_DESIGN          } from '../modules/local/dgereports/report_design'
include { REPORT_ALL             } from '../modules/local/dgereports/report_all'
include { GET_RANK_FILE          } from '../modules/local/gsea/get_rank_file'
include { GSEA_PRERANKED         } from '../modules/local/gsea/gsea_preranked'
include { PLOT_FROM_GSEA_RESULTS } from '../modules/local/gsea/plot_gsea'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow DGE {

    ch_versions = Channel.empty()

    //
    // MODULE : Run CREATE_PARAM_FILE
    //
    CREATE_PARAM_FILE (
        ch_inputdir,
        ch_metadata,
        ch_design,
        ch_condition,
        ch_treatment,
        ch_control,
        ch_pval,
        ch_fc
    )
    ch_versions = ch_versions.mix(CREATE_PARAM_FILE.out.versions.unique())

    //
    // MODULE: Run DESEQ2
    //
    DESEQ2 (
        ch_inputdir,
        ch_metadata,
        CREATE_PARAM_FILE.out.deseq2_conf
    )
    ch_versions = ch_versions.mix(DESEQ2.out.versions.unique())

    ch_resNorm = Channel.empty()
    if (params.design) {
        //
        // MODULE: Run REPORTDESIGN
        //
        REPORT_DESIGN (
            DESEQ2.out.dds,
            DESEQ2.out.colData,
            CREATE_PARAM_FILE.out.deseq2_conf
        )
        ch_versions = ch_versions.mix(REPORT_DESIGN.out.versions.unique())
        ch_resNorm = ch_resNorm.mix(REPORT_DESIGN.out.resNorm)

    } else {
        //
        // MODULE: Run REPORTALL
        //
        REPORT_ALL (
            DESEQ2.out.dds,
            DESEQ2.out.colData,
            CREATE_PARAM_FILE.out.deseq2_conf
        )
        ch_versions = ch_versions.mix(REPORT_ALL.out.versions.unique())
        ch_resNorm = ch_resNorm.mix(REPORT_ALL.out.resNorm)

    }

    if (!params.skip_gsea) {

        // Add meta.id (contrast) to reNorm to be able to separate each contrast in publishDir
        ch_resNorm_flat = ch_resNorm.flatten()
            | map { file ->
                contrast = file.baseName - ~/_results/
                meta = [id:contrast]
                [meta, file]
            }

        //
        // MODULE: Run GET_RANK_FILE
        //
        GET_RANK_FILE (
            ch_resNorm_flat
        )
        ch_versions = ch_versions.mix(GET_RANK_FILE.out.versions.first())

        //
        // MODULE: Run GSEA_PRERANKED
        //
        GSEA_PRERANKED (
            GET_RANK_FILE.out.rank.combine(ch_gmt).combine(ch_minset).combine(ch_maxset).combine(ch_perm)
        )
        ch_versions = ch_versions.mix(GSEA_PRERANKED.out.versions.first())

        //
        // MODULE: Run PLOT_GSEA
        //
        PLOT_FROM_GSEA_RESULTS (
            GSEA_PRERANKED.out.gsea_path.combine(ch_perm)
        )
        ch_versions = ch_versions.mix(PLOT_FROM_GSEA_RESULTS.out.versions.first())

    }

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

workflow.onError {
    if (workflow.errorReport.contains("Process requirement exceeds available memory")) {
        println("🛑 Default resources exceed availability 🛑 ")
        println("💡 See here on how to configure pipeline: https://nf-co.re/docs/usage/configuration#tuning-workflow-resources 💡")
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
