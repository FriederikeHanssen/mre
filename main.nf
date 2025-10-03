process DEBUG_MSISENSOR2 {
      publishDir "{params.outdir}/debug_output", mode: 'copy'
      container 'ghcr.io/friederikehanssen/msisensor2:upstream-test'
      output:
      path "cpu_flags.txt"
      path "msisensor2_test.txt"

      script:
      """
      # Check CPU features
      cat /proc/cpuinfo | grep flags | head -1 > cpu_flags.txt
      
      # Check container OS
      cat /etc/os-release >> cpu_flags.txt
      
      # Check glibc version
      ldd --version >> cpu_flags.txt
      
      # Test msisensor2
      msisensor2 2>&1 > msisensor2_test.txt || echo "Exit code: \$?" >> msisensor2_test.txt
      
      # Check library dependencies
      ldd \$(which msisensor2) >> msisensor2_test.txt

        # Test with help flag
        msisensor2 -h 2>&1 > msisensor2_test.txt || echo "Exit code: \$?" >> msisensor2_test.txt

        # Or just run the version check like the conda test does
        msisensor2 2>&1 | grep -i version || echo "No version found"
      """
  }

  workflow {
    DEBUG_MSISENSOR2()
  }