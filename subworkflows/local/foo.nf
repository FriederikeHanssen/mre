/*
 * FOO subworkflow
 * ---------------
 * Note how every value this subworkflow needs arrives through `take:`.
 * It never reads `params.*` — that keeps its dependencies visible in the
 * signature and makes it reusable and unit-testable in isolation.
 */

process MOCK_FOO {
    tag "${meta.id}"

    input:
    tuple val(meta), path(item)
    path foo
    val max_items

    output:
    tuple val(meta), path("${meta.id}.foo.txt"), emit: result

    script:
    """
    echo "processed ${item} against ${foo} (max_items=${max_items})" > ${meta.id}.foo.txt
    """
}

workflow FOO {

    take:
    samplesheet   // path to the input samplesheet
    foo           // resolved reference input (cache or primary), never null here
    max_items     // Integer

    main:

    ch_items = channel.fromPath(samplesheet)
        .splitCsv(header: true)
        .map { row -> [ [id: row.sample], file(row.item) ] }

    MOCK_FOO(ch_items, foo, max_items)

    emit:
    result = MOCK_FOO.out.result
}
