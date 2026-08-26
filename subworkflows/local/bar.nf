/*
 * BAR subworkflow
 * ---------------
 * Only invoked when the optional `--bar` is supplied. Again, all inputs
 * (including the optional `bar` / `bar_config`) are passed in explicitly
 * rather than read from `params.*`.
 */

process MOCK_BAR {
    tag "${meta.id}"

    input:
    tuple val(meta), path(foo_result)
    path bar
    path bar_config

    output:
    tuple val(meta), path("${meta.id}.bar.txt"), emit: result

    script:
    """
    echo "combined ${foo_result} with ${bar} using config ${bar_config}" > ${meta.id}.bar.txt
    """
}

workflow BAR {

    take:
    foo_result   // result from FOO
    bar          // Path (guaranteed non-null by the caller)
    bar_config   // Path (validated as required when bar is set)

    main:
    MOCK_BAR(foo_result, bar, bar_config)

    emit:
    result = MOCK_BAR.out.result
}
