#!/bin/bash

# Clean SLURM output, job lists, etc. produced with submission scripts

find . -name "slurm*" -type d -exec rm -r {} +
rm batchlist.txt
rm arrayjobs.sh
