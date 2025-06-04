# mre

For testing locally:

1. Set a secret: ` nextflow secrets set RIKE_SECRET "Hello world"`
2. Run pipeline: (tested with both, version that originally released it and newer version):
              - `NXF_VER=24.03.0-edge nextflow run main.nf` 
              - `NXF_VER=24.10.5 nextflow run .`

For testing on Platform + AWS Batch

1. Set up a workspace etc. Define a RIKE_SECRET. Add the pipeline to the launchpad, ensure it is part of the Workflow secrets.
2. Run pipeline

### Program output 

Locally:
```
❯ nextflow run .

 N E X T F L O W   ~  version 24.10.5

Launching `./main.nf` [special_montalcini] DSL2 - revision: d462ac85b4

The secret in Workflow is: Hello world
ERROR ~ Failed to invoke `workflow.onComplete` event handler

 -- Check script 'main.nf' at line: 6 or see '.nextflow.log' file for more details
```

AWS Batch & platform:

```
The secret in Workflow is: null

ERROR ~ Failed to invoke `workflow.onComplete` event handler
-- Check script '.nextflow/assets/FriederikeHanssen/mre/main.nf' at line: 6 or see 'nf-1Sc7D9V8WrFVRF.log' file for more details

```
