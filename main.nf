workflow {

    log.info("The secret in Workflow is: ${secrets.RIKE_SECRET}")

    workflow.onComplete {
        log.info("The secret on Complete is: ${secrets.RIKE_SECRET}")
    }

}


