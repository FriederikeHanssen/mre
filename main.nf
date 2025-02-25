process COWSAY {

    container 'community.wave.seqera.io/library/cowpy:1.1.5--3db457ae1977a273'[]

    script:
    """
    cowpy
    """
}

workflow  {

    COWSAY()
    
}