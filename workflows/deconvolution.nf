/*
========================================================================================
    VALIDATE INPUTS
========================================================================================
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

/*
========================================================================================
    CONFIG FILES
========================================================================================
*/

//ch_multiqc_config        = file("$projectDir/assets/multiqc_config.yaml", checkIfExists: true)
//ch_multiqc_custom_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config) : Channel.empty()

/*
========================================================================================
    IMPORT LOCAL MODULES/SUBWORKFLOWS
========================================================================================
*/

//def modules = params.modules.clone()

include { GET_SOFTWARE_VERSIONS } from "$projectDir/modules/local/get_software_versions" addParams( options: [publish_files : ['tsv':'']] )
include { cellbender_deconvolution } from "$projectDir/subworkflows/cellbender"
include { prepare_inputs } from "$projectDir/subworkflows/prepare_inputs"
include { deconvolution_module } from "$projectDir/subworkflows/deconvolution"
/*
========================================================================================
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
========================================================================================
*/

//def multiqc_options   = modules['multiqc']
//multiqc_options.args += params.multiqc_title ? Utils.joinModuleArgs(["--title \"$params.multiqc_title\""]) : ''

/*
========================================================================================
    RUN MAIN WORKFLOW
========================================================================================
*/

// Info required for completion email and summary
def multiqc_report = []

workflow DECONVOLUTION {

    // ###################################
    // ################################### Readme
    // Step1. CELLBENDER
    // There are 3 modes of running YASCP pipeline: 
    // (option 1) users can run it from 10x data and use cellbender -  params.input == 'cellbender' 
    // (option 2) users can run it from existing cellbender if the analysis has already been performed -  params.input == 'existing_cellbender' : note a specific folder structure is required
    // (option 3) users can run it from cellranger - skipping the cellbender. params.input == 'cellranger'
    // ###################################
    // ###################################

    if (!params.skip_preprocessing.value){
        // The input table should contain the folowing columns - experiment_id	n_pooled	donor_vcf_ids	data_path_10x_format
        input_channel = Channel.fromPath(params.input_data_table, followLinks: true, checkIfExists: true)
        // prepearing the inputs from a standard 10x dataset folders.
        prepare_inputs(input_channel)
        log.info 'The preprocessing has been already performed, skipping directly to h5ad input'

        if (params.preprocess){
            cellbender_deconvolution(params.input, prepare_inputs) 
        }else{
            //prepare data for direct deconvolution
        }
    }

    // ###################################
    // ################################### Readme
    // Step2. DECONVOLUTION
    // When thepreprocessing with cellbender or cellranger is finalised then we can do the deconvolution of samples. This can also be skipped if the samples are not multiplexed.
    // However if the number of individuals is specified as 1 the deconvolution withh be skipped anyways, but we will apply scrubblet to remove dublicates.
    // Suggestion is to still run deconvolution so that dublicates are removed.
    // ###################################
    // ###################################
    if (params.run_deconvolution){
        deconvolution_module()
    }
}

/*
========================================================================================
    COMPLETION EMAIL AND SUMMARY
========================================================================================
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
}

/*
========================================================================================
    THE END
========================================================================================
*/
