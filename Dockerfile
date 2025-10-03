FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    libgomp1 \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Download the binary directly from GitHub
RUN wget https://github.com/niu-lab/msisensor2/raw/master/msisensor2 -O /usr/local/bin/msisensor2 && \
    chmod +x /usr/local/bin/msisensor2

# Test it works
RUN msisensor2 || true

CMD ["/bin/bash"]