process GENERATE_REPORT {
    container "community.wave.seqera.io/library/pip_pandas:40d2e76c16c136f0"

    input:
    path(json) //, path(npz)

    output:
    path "*.tsv", emit: tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    template "report.py"
}