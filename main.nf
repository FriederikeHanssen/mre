process cowpy_script {

    publishDir 'results', mode: 'copy'

    container 'community.wave.seqera.io/library/cowpy:1.1.5--3db457ae1977a273'

    output:
    path 'output-script.txt'

    script:
    """
    ${projectDir}/bin/cowpy > output-script.txt
    """


}

process cowpy_container {

    publishDir 'results', mode: 'copy'

    container 'community.wave.seqera.io/library/cowpy:1.1.5--3db457ae1977a273'

    output:
    path 'output-container.txt'

    script:
    """
    cowpy -c dragonandcow 'Hello' > output-container.txt
    """


}

workflow{

    cowpy_script()
    cowpy_container()
}