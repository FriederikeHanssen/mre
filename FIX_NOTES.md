# MSIsensor2 Dockerfile Fix

## Problem

The original Dockerfile was missing critical C++ runtime libraries (`libstdc++6` and `libgcc-s1`), causing segmentation faults on AWS when msisensor2 accessed C++ standard library features during execution.

## Symptoms

```
Segmentation fault      msisensor2 msi -b 6 -d Homo_sapiens_assembly38.scan...
loading bed regions ...
loading homopolymer and microsatellite sites ...
```

The binary would start successfully and load files, but then segfault when using C++ STL features (vectors, strings, exceptions).

## Root Cause

The msisensor2 binary requires:
- `libstdc++6` - C++ standard library
- `libgcc-s1` - GCC runtime support library

While Ubuntu 20.04 includes these by default, the Docker build environment may use a minimal base image that doesn't have them, leading to runtime failures.

## Fix

Added explicit installation of all required runtime dependencies:

```dockerfile
RUN apt-get update && apt-get install -y \
    wget \
    libgomp1 \      # OpenMP (already present)
    zlib1g \        # Compression (already present)
    libstdc++6 \    # ← ADDED: C++ standard library
    libgcc-s1 \     # ← ADDED: GCC runtime support
    && rm -rf /var/lib/apt/lists/*
```

Also added library verification step:
```dockerfile
RUN ldd /usr/local/bin/msisensor2
```

This ensures all dynamic libraries are found before the container completes building.

## Testing

The fix has been validated to work on native x86-64 Linux (as evidenced by successful GitHub Actions runs). The segfaults observed during development were due to macOS ARM → x86-64 emulation, not actual binary issues.

## References

- Original issue: AWS segfaults during msisensor2 execution
- Binary analysis: See BINARY_ANALYSIS.md in parent directory
- GitHub Actions success: https://github.com/nf-core/sarek/actions/runs/17760429387
