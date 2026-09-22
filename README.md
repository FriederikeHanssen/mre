# Cached task email notifications with `sendMail()`

This minimal Nextflow pipeline compares two ways of sending an email when a task finishes:

1. Calling `sendMail()` from an output-channel subscription.
2. Calling `sendMail()` from a native, cacheable Nextflow process.

The example shows why the second approach is preferable when resumed workflows should not resend notifications for cached results.

## Pipeline structure

```text
names
  │
  ▼
SAY_HELLO ──► SEND_MAIL ──► email with greeting.txt attached
  │
  ▼
TO_UPPER ──► subscribe ──► email with shouting.txt attached
```

With four names, each processing step creates four tasks.

## The behavior being tested

### Output subscription

`TO_UPPER.out.subscribe` calls `sendMail()` whenever the channel emits an item:

```nextflow
TO_UPPER.out.subscribe { name, file ->
    sendMail(
        to: params.email,
        subject: "TO_UPPER finished for ${name}",
        body: "The TO_UPPER task for ${name} has completed.",
        attach: file
    )
}
```

Cached tasks emit their saved outputs again during `-resume`. The subscription therefore runs again and resends the emails.

Using `map` instead of `subscribe` does not change this behavior. Both operators run for values emitted from cached tasks.

### Native notification process

`SEND_MAIL` is a native Nextflow process:

```nextflow
process SEND_MAIL {
    input:
    tuple val(name), val(attachment)
    val recipient

    exec:
    sendMail(
        to: recipient,
        subject: "SAY_HELLO finished for ${name}",
        body: "The SAY_HELLO task for ${name} has completed. Output attached.",
        attach: attachment
    )
}
```

It is called with:

```nextflow
SEND_MAIL(SAY_HELLO.out, params.email)
```

A native process runs its `exec:` block in the Nextflow JVM. It still participates in normal Nextflow task caching. When a successful `SEND_MAIL` task is restored during `-resume`, its `exec:` block is not run and the email is not sent again.

The recipient is an explicit process input so that changing it changes the task cache key.

## Why the attachment uses `val`

A normal `script:` process stages a `path` input into its task directory before running its command. A native `exec:` process does not perform that normal staging step.

If the native process declares:

```nextflow
tuple val(name), path(attachment)
```

the attachment is bound to a staged filename such as `greeting.txt`, but the file is not placed in the native task’s work directory. `sendMail()` therefore reports that the attachment does not exist.

The MRE instead declares:

```nextflow
tuple val(name), val(attachment)
```

This preserves the `Path` object emitted by the upstream process. The pipeline does not contain a hard-coded absolute path; the path is passed through the dataflow connection. The Nextflow JVM reads the attachment directly from the upstream work directory.

This approach requires the machine running Nextflow to be able to read the work storage. It works with the local executor and should be tested with the actual remote executor and work-storage configuration before production use.

## Run locally with Mailpit

Start Colima and Mailpit:

```bash
colima start

docker --context colima run -d \
    --name mailpit \
    -p 1025:1025 \
    -p 8025:8025 \
    axllent/mailpit
```

If the container already exists:

```bash
docker --context colima start mailpit
```

Configure the SMTP connection:

```bash
export SMTP_HOST=127.0.0.1
export SMTP_PORT=1025
unset SMTP_USER SMTP_PASSWORD
```

Run the pipeline:

```bash
nextflow run main.nf --email demo@example.com
```

View the captured messages at [http://localhost:8025](http://localhost:8025).

## Test resume behavior

Run the pipeline again:

```bash
nextflow run main.nf --email demo@example.com -resume
```

Expected behavior:

- `SAY_HELLO`, `TO_UPPER`, and `SEND_MAIL` are reported as cached.
- `SEND_MAIL` does not resend its messages because its `exec:` block is skipped.
- The `TO_UPPER.out.subscribe` callback sends its messages again because cached outputs are emitted again.

With four names, the first run should produce:

- Four emails from `SEND_MAIL`.
- Four emails from the `TO_UPPER` subscription.

The resumed run should produce:

- No new emails from `SEND_MAIL`.
- Four additional emails from the subscription.

## Limits

This prevents duplicate delivery during a normal `-resume` when the notification task previously completed successfully.

It is not a strict exactly-once guarantee. If the SMTP server accepts a message but the notification task fails before Nextflow records success, a retry could send the message again. Preventing that case requires a stable notification ID and a durable external idempotency record.

The native process also runs on the Nextflow host rather than inside a task container. The Nextflow host must therefore have network access to the SMTP server and read access to the attachment.