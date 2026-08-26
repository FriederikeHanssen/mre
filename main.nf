#!/usr/bin/env nextflow

/*
 * Showcase: optional parameters with typed params + nf-schema (Nextflow 26.04)
 * ---------------------------------------------------------------------------
 * The `params {}` block below is the single, typed contract for the pipeline.
 *
 *   foo: Path             -> always required (non-nullable, no default)
 *   max_items: Integer=100-> optional, has a default
 *   bar: Path?            -> optional (nullable), no `= null` workaround
 *   save_intermeds: Boolean -> optional, defaults to false in 26.04
 *
 * Typed params are referenced ONLY here in the entry workflow (and the output
 * block). Every subworkflow receives the values it needs through its `take:`
 * signature, so no subworkflow reads `params.*` directly.
 */

include { validateParameters ; paramsSummaryLog } from 'plugin/nf-schema'

include { FOO } from './subworkflows/local/foo.nf'
include { BAR } from './subworkflows/local/bar.nf'

params {
    // --- Always required ----------------------------------------------------
    input: Path                                 // samplesheet
    foo: Path                                   // primary reference input (required)

    // --- Optional with a default -------------------------------------------
    max_items: Integer = 100
    mode: String = 'quick'                      // one of: quick, full

    // --- Optional, nullable (no `= null` needed) ---------------------------
    foo_cache: Path?                            // pre-staged `foo`, used if present
    bar: Path?                                  // enables the optional BAR branch
    bar_config: Path?                           // required ONLY when `bar` is set

    // --- Optional flag ------------------------------------------------------
    save_intermeds: Boolean                     // defaults to false in 26.04
}

workflow {

    main:

    // 1. Structural validation against the JSON schema (types, enums, ...).
    validateParameters()
    log.info paramsSummaryLog(workflow)

    // 2. Conditional ("depends-on") requirements the JSON schema can't express
    //    on its own. Validate them early, in the entry workflow.
    if( params.bar && !params.bar_config )
        error "`--bar` was provided, so `--bar_config` is also required."

    if( params.mode == 'full' && !params.foo_cache )
        error "`--mode full` requires `--foo_cache`."

    // 3. Pass typed params EXPLICITLY into subworkflows via their take: blocks.
    //    `foo_cache` may be null -> the elvis operator picks the fallback.
    FOO(
        params.input,
        params.foo_cache ?: params.foo,
        params.max_items,
    )

    // 4. Optional branch: only run BAR when the optional input was supplied.
    ch_bar = channel.empty()
    if( params.bar ) {
        BAR(FOO.out.result, params.bar, params.bar_config)
        ch_bar = BAR.out.result
    }

    publish:
    foo_out = FOO.out.result
    bar_out = ch_bar
}

output {
    foo_out {
        path 'foo'
    }
    bar_out {
        path 'bar'
    }
}
