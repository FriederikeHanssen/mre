workflow {

    println("The secret in Workflow is: ${secrets.RIKE_SECRET}")

    workflow.onComplete {
        println("The secret on Complete is: ${secrets.RIKE_SECRET}")
    }

}


