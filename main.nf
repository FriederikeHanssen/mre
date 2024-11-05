include { GENERATE_REPORT }     from './modules/report.nf'

workflow  {

    main:

    json = Channel.fromPath('data.json')

    GENERATE_REPORT(json)
    
}