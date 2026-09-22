#!/usr/bin/env nextflow

/*
 * sendMail task-notification demo
 * --------------------------------
 * The same idea as the nf-slack demo, but using Nextflow's built-in
 * `sendMail()` function instead of a plugin: send an email every time an
 * individual task finishes — not just when the whole workflow completes.
 *
 * Note: there is no `sendMail` *directive*. `sendMail()` is a function that
 * can be called anywhere in the pipeline code. By `.subscribe`-ing to each
 * process's output channel, we get one callback per emitted item, i.e. one
 * email per completed task. No plugin required.
 */

// Where to send the per-task emails.
params.email = 'you@example.com'

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

process SEND_MAIL {

    input:
    tuple val(name), val(file)

    exec:
    sendMail(
            to:      params.email,
            subject: "PROCESS sends emails",
            body:    "The TO_UPPER task for ${name} has completed. Output attached.",
            attach:  file
        )
}

workflow {

    greetings_ch = Channel.fromList(params.greetings)

    // --- Process 1 -------------------------------------------------------
    SAY_HELLO(greetings_ch)

    SEND_MAIL(SAY_HELLO.out)

    // --- Process 2 -------------------------------------------------------
    TO_UPPER(SAY_HELLO.out)

    TO_UPPER.out.subscribe { name, file ->
        sendMail(
            to:      params.email,
            subject: "TO_UPPER finished for ${name}",
            body:    "The TO_UPPER task for ${name} has completed. Output attached.",
            attach:  file
        )
    }

}
