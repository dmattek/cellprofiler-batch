#!/bin/bash

# Singularity wrapper script

# Location of Singularity image
IMLOC=/opt/CellProfiler/cp2ubuntu.img

# List of directories to bind with the image
BNDDIR="-B /scratch -B /mnt/imaging.data"

# execute "runscript" section of the image
singularity run $BNDDIR $IMLOC $@
