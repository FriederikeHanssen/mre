workflow {

    println("The secret in Workflow is: ${secrets.MY_SECRET}")

    workflow.onComplete {
        println("The secret on Complete is: ${secrets.MY_SECRET}")
    }

}


