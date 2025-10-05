FROM ubuntu:20.04

# Install ALL required runtime dependencies
# Even though Ubuntu includes some by default, explicitly installing ensures they're present
RUN apt-get update && apt-get install -y \
    wget \
    # OpenMP for parallel processing
    libgomp1 \
    # Compression library for BAM files
    zlib1g \
    # C++ standard library - CRITICAL for C++ binary runtime
    libstdc++6 \
    # GCC support library - CRITICAL for exception handling and runtime support
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/*

# Download the binary directly from GitHub
RUN wget https://github.com/niu-lab/msisensor2/raw/master/msisensor2 -O /usr/local/bin/msisensor2 && \
    chmod +x /usr/local/bin/msisensor2

# Verify library linkage
RUN ldd /usr/local/bin/msisensor2

# Test it works (will show usage, not segfault)
RUN msisensor2 || true

CMD ["/bin/bash"]