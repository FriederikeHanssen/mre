#!/usr/bin/env nextflow

/*
 * Demo: writing a samplesheet with the workflow output syntax
 * -----------------------------------------------------------
 * The new `output {}` block can publish a channel of metadata maps
 * as a CSV "index" (samplesheet). Every key of the published map
 * becomes a column, so we can freely mix sample metadata with the
 * paths of the files each sample produced.
 *
 * The result is a restart samplesheet: one row per library, with the
 * metadata that describes it and the published paths to its outputs.
 */

/*
 * Stand-in for a real alignment / quantification step. It just touches
 * the files a single-cell run would normally emit, so the outputs are
 * genuine channel files that the output block can publish.
 */
process MOCK_ALIGN {
    tag "${meta.library_id}"

    input:
    val meta

    output:
    tuple val(meta),
          path("${meta.library_id}.aligned.bam"),
          path("${meta.library_id}.aligned.bam.bai"),
          path("${meta.library_id}.dge_summary.txt"),
          path("${meta.library_id}.reads_per_cell.csv")

    script:
    """
    echo "mock BAM for ${meta.library_id}"            > ${meta.library_id}.aligned.bam
    echo "mock BAI for ${meta.library_id}"            > ${meta.library_id}.aligned.bam.bai
    echo "gene,cells\\nGAPDH,1234"                     > ${meta.library_id}.dge_summary.txt
    echo "barcode,reads\\nAAACCTGAGAAACCAT,5821"       > ${meta.library_id}.reads_per_cell.csv
    """
}

workflow {

    main:

    // A few mock libraries, each described by a metadata map.
    def libraries = [
        [ library_id: 'library_A', split_index: 3, reference_id: 'GRCh38', cbrb_variant: 'variant_01' ],
        [ library_id: 'library_B', split_index: 1, reference_id: 'GRCh38', cbrb_variant: 'variant_02' ],
        [ library_id: 'library_C', split_index: 5, reference_id: 'GRCm39', cbrb_variant: 'variant_01' ],
    ]

    // Feed each library's metadata into the mock process.
    restart_ch = MOCK_ALIGN(Channel.fromList(libraries))
        .map { meta, aligned_bam, aligned_bai, dge_summary, reads_per_cell ->
            // Group the emitted files under a `files` map, mirroring how a
            // real pipeline would carry named outputs alongside `meta`.
            def files = [
                aligned_bam   : aligned_bam,
                aligned_bai   : aligned_bai,
                dge_summary   : dge_summary,
                reads_per_cell: reads_per_cell,
            ]
            [ meta, files ]
        }

    // Flatten each record into a single map: metadata + file paths.
    // This map is exactly one row of the samplesheet.
    restart_rows = restart_ch.map { meta, files ->
        meta + [
            aligned_bam   : files.aligned_bam,
            aligned_bai   : files.aligned_bai,
            dge_summary   : files.dge_summary,
            reads_per_cell: files.reads_per_cell,
        ]
    }

    publish:
    restart_sheet = restart_rows
}

output {
    restart_sheet {
        // Copy the referenced files here...
        path 'restart/files'

        // ...and write one CSV row per record, with map keys as columns.
        index {
            path 'restart/samplesheet.csv'
            header true
        }
    }
}
