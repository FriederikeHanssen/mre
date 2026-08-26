#!/usr/bin/env nextflow

include { slackMessage } from 'plugin/nf-slack'

// A handful of greetings so we fan out into several parallel tasks.
params.greetings = ['Ada', 'Alan', 'Grace', 'Linus']

process SAY_HELLO {
    tag "$name"

    input:
    val name

    output:
    tuple val(name), path("greeting.txt")

    script:
    """
    echo "Hello, ${name}!" > greeting.txt
    """
}

process TO_UPPER {
    tag "$name"

    input:
    tuple val(name), path(greeting)

    output:
    tuple val(name), path("shouting.txt")

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${greeting} > shouting.txt
    """
}

workflow {

    greetings_ch = Channel.fromList(params.greetings)

    // --- Process 1 -------------------------------------------------------
    SAY_HELLO(greetings_ch)

    // One Slack message per completed SAY_HELLO task.
    SAY_HELLO.out.subscribe { name, file ->
        slackMessage(":wave: `SAY_HELLO` finished for *${name}*")
    }

    // --- Process 2 -------------------------------------------------------
    TO_UPPER(SAY_HELLO.out)

    // One Slack message per completed TO_UPPER task.
    TO_UPPER.out.subscribe { name, file ->
        slackMessage(":loud_sound: `TO_UPPER` finished for *${name}*")
    }
}
