# sendMail task-notification demo

A minimal two-process Nextflow pipeline that sends an email **every time an
individual task finishes** — not just when the whole workflow completes — using
Nextflow's built-in [`sendMail()`](https://docs.seqera.io/nextflow/notifications)
function. No plugin required.

This is the email counterpart of the `nf-slack-task-notification` branch.

## What it does

The pipeline fans a list of names out into parallel tasks:

```
Channel.fromList([Ada, Alan, Grace, Linus])
        │
        ▼
   SAY_HELLO   ──►  📧 one email per task
        │
        ▼
   TO_UPPER    ──►  📧 one email per task
```

- `SAY_HELLO` writes `Hello, <name>!` to a file.
- `TO_UPPER` uppercases that greeting.

With four names, that's four independent tasks per process — and one email for
each as it completes.

## The key idea

`sendMail()` is a **function** built into Nextflow (there is *no* `sendMail`
directive). It can be called anywhere in the pipeline code:

```groovy
sendMail(
    to:      params.email,
    subject: "SAY_HELLO finished for ${name}",
    body:    "The SAY_HELLO task for ${name} has completed."
)
```

Nextflow's built-in mail hooks only fire at the **workflow** level (e.g.
`workflow.onComplete` or the `-N` flag). To get a notification per **task**,
subscribe to a process's output channel — each emitted item corresponds to one
completed task:

```groovy
SAY_HELLO.out.subscribe { name, file ->
    sendMail(to: params.email, subject: "SAY_HELLO finished for ${name}", body: "...")
}
```

`.subscribe` runs the closure once for every item the channel emits, so you get
exactly one email per finished task, tagged with which sample it was for.

## Sending a file (attachment)

`sendMail()` takes an `attach:` argument to attach one or more files. Here each
per-task email carries that task's output file — the file is already in scope as
the second element of the output tuple:

```groovy
SAY_HELLO.out.subscribe { name, file ->
    sendMail(
        to:      params.email,
        subject: "SAY_HELLO finished for ${name}",
        body:    "The SAY_HELLO task for ${name} has completed. Output attached.",
        attach:  file
    )
}
```

- **Multiple files:** pass a list — `attach: [file, 'results/report.html']`.
- **Custom filename / inline images:** pass a map (or list of maps) —
  `attach: [file, contentId: 'greeting', fileName: "${name}.txt"]`.

The attached path must exist when the email is sent. Because `.subscribe` fires
as soon as the task completes, the staged output file is present, so attaching it
directly works.

## Configuration

`nextflow.config` sets the SMTP server for `sendMail()`, reading everything from
the environment so no credentials are committed:

```groovy
mail {
    from = System.getenv('SMTP_USER') ?: 'nextflow@localhost'
    smtp {
        host     = System.getenv('SMTP_HOST')
        port     = (System.getenv('SMTP_PORT') ?: '587') as Integer
        user     = System.getenv('SMTP_USER')
        password = System.getenv('SMTP_PASSWORD')
    }
}
```

If you leave the SMTP settings unset, Nextflow falls back to the local
`sendmail`/`mail` command on the host.

## Running it

1. Point the config at an SMTP server and set the recipient:

   ```bash
   export SMTP_HOST=smtp.gmail.com SMTP_PORT=587
   export SMTP_USER=you@example.com SMTP_PASSWORD=your-app-password
   nextflow run main.nf --email you@example.com
   ```

2. Check your inbox: one email as each `SAY_HELLO` task finishes, and one as
   each `TO_UPPER` task finishes.

### Testing locally without a real inbox

Use a local SMTP catcher such as [MailHog](https://github.com/mailhog/MailHog)
or [Mailpit](https://github.com/axllent/mailpit), which listen on
`localhost:1025` and show captured mail in a web UI:

```bash
export SMTP_HOST=localhost SMTP_PORT=1025 SMTP_USER= SMTP_PASSWORD=
nextflow run main.nf --email demo@example.com
```

## Notes

- Sending one email per task can be a lot of mail — the `.subscribe` fires per
  completed task by design. Adjust `params.greetings` to fan out into more or
  fewer tasks.
- Unlike the nf-slack plugin's custom messages, `sendMail()` throws on SMTP
  errors, so a misconfigured server will surface loudly rather than fail
  silently.
