process HELLO {

    secret 'SECRET'

    input:
    tuple val(meta), path(file)

    output:
    tuple val(meta), path("*.txt"), emit:hello

    script:
    """

    echo \$SECRET
    echo "buenos dias" >> ${file}
    mv ${file} hello_${file} 
    """
}