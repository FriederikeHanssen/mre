# optional-params — typed params + nf-schema, done right (Nextflow 26.04)

A runnable, best-case example of declaring **optional / nullable parameters**
with the new typed `params {}` block **and** nf-schema — without the `= null`
workarounds people reach for when a "missing parameter" error won't go away.

## Requires

Nextflow `>=26.04.0`:

```bash
NXF_VER=26.04.0 nextflow run main.nf --input assets/samplesheet.csv --foo test-data/foo.txt
```

## The parameter contract lives in `main.nf`

```nextflow
params {
    input: Path                  // required (non-nullable, no default)
    foo: Path                    // required

    max_items: Integer = 100     // optional, has a default
    mode: String = 'quick'       // optional, has a default (enum: quick, full)

    foo_cache: Path?             // optional -> nullable, NO `= null`
    bar: Path?                   // optional
    bar_config: Path?            // conditionally required (see below)

    save_intermeds: Boolean      // optional flag, defaults to false in 26.04
}
```

### Why this fixes the usual fudging

| Common workaround | Fix shown here |
| --- | --- |
| Optional params declared non-nullable (`bar: Path`) → Nextflow treats them as **required** | Declare them **nullable**: `bar: Path?` |
| `params.bar = null` added in `nextflow.config` to silence "missing parameter" errors | Deleted — nullability is expressed in the type, not the config |
| Subworkflows read `params.*` directly, hiding their dependencies | Every value is passed in through `take:` (see `subworkflows/local/`) |
| Conditional requirements (`bar_config` needed iff `bar` set) not enforced | Validated **early in the entry workflow** with a clear error |

## Typed params are referenced only in the entry workflow

`main.nf` reads `params.*` in exactly one place — the entry `workflow` — and
passes the values into subworkflows explicitly:

```nextflow
FOO(
    params.input,
    params.foo_cache ?: params.foo,   // nullable → elvis fallback
    params.max_items,
)
```

Neither `subworkflows/local/foo.nf` nor `bar.nf` touches `params` — their inputs
are visible in their `take:` blocks, so they're reusable and testable in
isolation (see the nf-test docs on overriding params).

## Two validation layers, kept aligned

1. **Typed `params {}` block** — types, required-ness, nullability. Catches
   missing required params and type mismatches:
   ```
   [ERROR] Parameter `foo` is required but was not specified ...
   [ERROR] Parameter `max_items` with type Integer cannot be assigned to notanumber [String]
   ```
2. **nf-schema `validateParameters()`** against `nextflow_schema.json` — adds
   enums, patterns, file-path formats, and `--help` text:
   ```
   [ERROR] --mode (bogus): Expected any of [quick, full]
   ```

Keep them aligned: required params sit in the schema's `required` array with
**no default**; optional params have no `required` entry; defaults match the
typed block. A CI check comparing name/type/default/required across the two is
the recommended guard (see the nf-core parameter-types blog).

## Try the scenarios

```bash
export NXF_VER=26.04.0

# 1. Required only — optional params omitted, no null anywhere
nextflow run main.nf --input assets/samplesheet.csv --foo test-data/foo.txt

# 2. Conditional requirement fires: --bar needs --bar_config
nextflow run main.nf --input assets/samplesheet.csv --foo test-data/foo.txt \
    --bar test-data/bar.txt

# 3. Full run — BAR branch activates
nextflow run main.nf --input assets/samplesheet.csv --foo test-data/foo.txt \
    --bar test-data/bar.txt --bar_config test-data/bar_config.csv --max_items 250
```

## Docs

- [Nextflow: Typed parameters](https://docs.seqera.io/nextflow/typed-parameters)
- [Nextflow: Nullable types](https://docs.seqera.io/nextflow/reference/semantics#nullable-types)
- [nf-test: Overriding parameters](https://www.nf-test.com/docs/testcases/params/)
- [nf-core: Parameter types and lint compatibility](https://nf-co.re/blog/2026/parameter-types)
