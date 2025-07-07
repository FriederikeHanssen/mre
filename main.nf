nextflow.preview.output = true

include { HELLO } from './modules/hello.nf'

workflow {

    main:

    ch_hello = Channel.fromPath("./data/foo.txt").map{ file ->
      [[id: file.getName()], file]
    }

    HELLO(ch_hello)

    publish:
    ch_out = HELLO.out.hello
}

output {

    ch_out {
        path "out.txt"
    }
}