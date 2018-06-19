#!/bin/bash

# Wrapper for slsubarrcp script
# Submits CellProfiler batch analysis to SLURM queue using CP2 binary
# The script should be executed IN the directory with CP h5 batch file

# Definitions
# Path to main slsubarrcp script
SLPATH=/opt/local/bin/slsubarrcp.sh

# Path to CP3 binary
CPPATH=/opt/local/bin/runcp2.sh

# Run main script
$SLPATH -c $CPPATH "$@"
