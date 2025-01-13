process TOUCH {
    input:

    val message

    output:
    path('touch.txt'), emit: file
    script:
    """
    echo '$message' > touch.txt
    """
}

process DEFAULT {

    output:
    path('touch.txt'), emit: file

    script:
    """
    echo 'test' > touch.txt
    """
}

process APPEND {

    input:
    path(file)

    output:
    path('touch.txt'), emit: file

    script:
    """
    echo "second line" >> $file
    """
}

workflow {

    if(params.echo){
        echo = TOUCH(params.echo).file
    } else {
        echo = DEFAULT().file
    }

    APPEND(echo)

}