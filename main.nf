#!/usr/bin/env nextflow
/*
========================================================================================
    nf-core/
========================================================================================

----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    VALIDATE & PRINT PARAMETER SUMMARY
========================================================================================
*/

/*
========================================================================================
  NAMED WORKFLOWS FOR TESTS
========================================================================================
*/

//include { TEST_MATCH_GT_VIREO } from './tests/test_genotypes'
include { TEST_SPLIT_BAM_PER_DONOR } from "$projectDir/tests/test_bam_per_donor"

workflow NF_CORE_TEST {
  //println "**** running NF_CORE_TEST::TEST_MATCH_GT_VIREO"
  //TEST_MATCH_GT_VIREO()
  println "**** running NF_CORE_TEST::TEST_SPLIT_BAM_PER_DONOR"
  TEST_SPLIT_BAM_PER_DONOR()
}

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { DECONVOLUTION } from "$projectDir/workflows/deconvolution"

//
// WORKFLOW: Run main nf-core/yascp analysis pipeline
//
workflow DECONVOLUTION_PIPELINE {
    DECONVOLUTION ()
}

/*
========================================================================================
    RUN ALL WORKFLOWS
========================================================================================
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    DECONVOLUTION_PIPELINE ()
}

/*
========================================================================================
    THE END
========================================================================================
*/
