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

workflow {

    greetings_ch = Channel.fromList(params.greetings)

    // --- Process 1 -------------------------------------------------------
    SAY_HELLO(greetings_ch)

    // One email per completed SAY_HELLO task, with the task's output file
    // attached (see the `attach:` argument).
    SAY_HELLO.out.subscribe { name, file ->
        sendMail(
            to:      params.email,
            subject: "SAY_HELLO finished for ${name}",
            body:    "The SAY_HELLO task for ${name} has completed. Output attached.",
            attach:  file
        )
    }

    // --- Process 2 -------------------------------------------------------
    TO_UPPER(SAY_HELLO.out)

    // One email per completed TO_UPPER task. `attach:` also accepts a list to
    // send several files, e.g. `attach: [file, 'results/report.html']`.
    TO_UPPER.out.subscribe { name, file ->
        sendMail(
            to:      params.email,
            subject: "TO_UPPER finished for ${name}",
            body:    "The TO_UPPER task for ${name} has completed. Output attached.",
            attach:  file
        )
    }
}
