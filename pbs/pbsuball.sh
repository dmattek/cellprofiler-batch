#!/bin/bash

########################################################################
#
# Script  name      : submitCP2PBS.sh
#
# Author            : Maciej Dobrzynski
#
# Contact           : macdobry [at] gmail [dot] com
#
# Date created      : 20171205
#
# Purpose           : process the output of CP's CreateBatchFiles module 
#                     Batch_data.h5 and submits jobs to the PBS queueing 
#                     system. Every job corresponds to a group created in 
#                     Groups module. 
#
# Result            : if default params unchanged, the script creates:
#                     - a 'batch.list' file with a list of CP commands
#                     - 'pbs.jobs' directory with files of the form 
#                       job_00xx.pbs
#                       ready to submit to PBS queueing system
#                     - 'output' directory with sub-directories of the form
#                       out_00xx
#                       with CP outputs from separate groups
#
# Example usage     : Execute the script in the folder with Batch_data.h5 file.
# 
# Tested on:
# Ubuntu 16.04.2 LTS
#
########################################################################

## Definitions

# path to CP executable
CPPATH=/usr/local/bin/cellprofiler


# Name of the h5 filer with experiment description.
# The file is produced by CP module CreateBatchFiles
FBATCHDATA=Batch_data.h5

# Name of the intermediate file to store the output of
# cellprofiler --get-batch-commands Batch_data.h5
FBATCHLIST=batch.list

# Directory to store job files for submission to PBS
JOBSDIR=pbs.jobs

# Name of the directory to store CP output (CSV result files, segmented images, etc.)
OUTDIR=output

# Location of jobs for submission; handy for PBS qsub command
FILECORE="${JOBSDIR}/job_"

# Directory with CP plugins
CPPLUGINSDIR="/home.nis/NIScp2/CellProfiler/plugins"

# Directory with ImageJ plugins
IJPLUGINSDIR="/home.nis/NIScp2/CellProfiler/imagej"

# Directory for temp files.
# Point it to a fast drive.
TMPDIR="/tmp/cp2"

## Create a list of CP commands to execute the analysis
# The list is based on experiment description stored in h5 file.
# The standard string "cellprofiler" is superseded by the path to CP executable.
# The result is stored in FBATCHLIST file

$CPPATH --get-batch-commands $FBATCHDATA |sed -e "s|CellProfiler|${CPPATH}|" > $FBATCHLIST


## Create PBS job files for submission

# Set the initial value for the loop below
nIt=1

# create necessary sub-directories
currDir=`pwd`
mkdir -p $JOBSDIR
mkdir -p $OUTDIR

# Loop over the content of FBATCHLIST file
while read p; do
	printf -v nItPadded "%04d" $nIt
	echo "#!/bin/sh" > $JOBSDIR/job_$nItPadded.pbs 
    echo "#PBS -l walltime=2:00:00" >> $JOBSDIR/job_$nItPadded.pbs
    echo "#PBS -d $currDir" >> $JOBSDIR/job_$nItPadded.pbs
	echo $p  --plugins-directory=$CPPLUGINSDIR --ij-plugins-directory=$IJPLUGINSDIR -o $OUTDIR/out_$nItPadded -t $TMPDIR >> $JOBSDIR/job_$nItPadded.pbs
	nIt=$(( nIt + 1 ))
done < $FBATCHLIST 

# Submit all jobs created in JOBSDIR to PBS queueing system
nFILES=`ls -l $FILECORE* |wc -l`

for ii in $(seq -f "%04g" 1 $nFILES); do qsub $FILECORE$ii.pbs ; done
