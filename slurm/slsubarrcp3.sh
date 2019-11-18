#!/bin/bash

# Script  name      : slsubarrcp3.sh
#
# Author            : Maciej Dobrzynski
#
# Last update       : 20191118
#
# Purpose           : Create and submit CellProfiler jobs to SLURM queue
#
# Example usage:
#  in the directory with Batch_data.h5
#  slsubarrcp3.sh Batch_data.h5
# 
# Jobs are generated based on h5 file (typically Batch_data.h5) created with CreateBatchFile module of CellProfiler
# The script should be execute IN the directory with h5 file
# 
# The rationale behind this script is as follows:
# 
# The image analysis pipeline prepared with CP GUI produces an H5 file with a description of the analysis.
# This file is produced if CreateBatchFile module of CP is placed at the end of the pipeline.
# Using a command-line option --get-batch-commands of CP, we can obtain a list of CP commands to execute
# and process chunks of data. These commands are of the form:
# /opt/local/bin/runcp3.sh -c -r -p Batch_data.h5 -f 1 -l 240
#
# This script then takes these commands and place each of them in separate shell scripts.
# Then, these scripts are submitted individually to SLURm queue as part of SLURM job array.
#
# Files created by this script:
# - batchlist.txt (file name defined by FBATCHLIST) from CellProfiler --get-batch-commands;
#   each row contains a CP command to execute on a chunk of data.
# - slurm.jobs/job_0001.sh ... (folder name defined by JOBSDIR) shell files, where each file 
#   corresponds to a single line of the batchlist file.
# - arrayjobs.sh (file name defined by FARRAY) main array submission file;
#   files destined for execution in the slurm.jobs folder are looped over using SLURM_ARRAY_TASK_ID system variable.
# - slurm.jobs.out - output of the SLURM run


usage="Error: insufficient arguments!
This script processes CellProfiler batch h5 file, creates jobs, and submits to SLURM queue

Usage: $(basename "$0") -options H5-batch-file-from-CP

Possible options:
	-h | --help		Show this help text.
	-t | --test		Test mode: creates all intermediate files without submitting to a queue.
	-c | --cpbin		Path to CellProfiler binary; default \$USERHOMEDIR/.local/bin/cellprofiler.
	-i | --cpinst		Path to CellProfiler install directory; default \$USERHOMEDIR/CellProfiler.
	-m | --tmpdir		Path to TEMP directory; default /tmp.
	-o | --outdir		Directory with CP output; defalut output.
	-r | --reqmem		Required memory per cpu; default 4GB.
	-e | --reqtime		Required time per task; default 6h.
	-p | --partition	Name of the slurm queue partition; default all."
	
E_BADARGS=85

if [ ! -n "$1" ]
then
  echo "$usage"
  exit $E_BADARGS
fi  

# -------------- Bash part for taking inputs -----------

# Definitions of global and default variables
# User home directory
USERHOMEDIR=`eval echo "~$USER"`

# Directory with CellProfiler install 
CPINSTDIR=/opt/local/cellprofiler

# Path to CellProfiler binary
CPBINPATH=/opt/local/bin/runcp3.sh

# CP plugins directory
CPPLUGDIR=$CPINSTDIR/plugins

# Name of the file with commands to execute
FBATCHLIST=batchlist.txt

# Name of the directory to store jobs for submission
JOBSDIR=slurm.jobs

# SLURM array submission file
FARRAY=arrayjobs.sh

# Name of the directory to store temporary files
TMPDIR=/tmp

# Name of the directory to store CP output
OUTDIR=output

# Required memory per cpu; default 4GB
REQMEMPERCPU=4096

# Required time per task; default 6 hours
REQTIME=6:00:00

# Name of the slurm partition to submit the job
SLPART=all

# Prefix for naming job files
FJOBCORE="job_"

# Suffix for job files
FJOBEXT=sh

# Test mode switch
TST=0

# read arguments
TEMP=`getopt -o thc:i:m:o:r:e:p: --long test,help,cpbin:,cpinst:,tmpdir:,outdir:,reqmem:,reqtime:,partition: -n 'slsubarrcp3.sh' -- "$@"`
eval set -- "$TEMP"

# Extract options and their arguments into variables.
# Tutorial at:
# http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt

while true ; do
	case "$1" in
	-t|--test) TST=1 ; shift ;;
	-h|--help) echo "$usage"; exit ;;	
	-c|--cpbin)
            case "$2" in
                "") shift 2 ;;
                *) CPBINPATH=$2 ; shift 2 ;;
            esac ;;
	-i|--cpinst)
            case "$2" in
                "") shift 2 ;;
                *) CPINSTDIR=$2 ; shift 2 ;;
            esac ;;
	-m|--tmpdir)
            case "$2" in
                "") shift 2 ;;
                *) TMPDIR=$2 ; shift 2 ;;
            esac ;;
	-o|--outdir)
            case "$2" in
                "") shift 2 ;;
                *) OUTDIR=$2 ; shift 2 ;;
            esac ;;
	-r|--reqmem)
            case "$2" in
                "") shift 2 ;;
                *) REQMEMPERCPU=$2 ; shift 2 ;;
            esac ;;
	-e|--reqtime)
            case "$2" in
                "") shift 2 ;;
                *) REQTIME=$2 ; shift 2 ;;
            esac ;;
	-p|--partition)
		case "$2" in
			"") shitf 2 ;;
			*) SLPART=$2 ; shift 2 ;;
		esac ;;
	--) shift ; break ;;
     *) echo "Internal error!" ; exit 1 ;;
    esac
done


# -------------- Write the array submission file ------------------

# Name of the h5 file generated with CreateBatchFile module of CP
# Provided in the command line
FBATCHDATA=$1

# Step 1
# Parse $FBATCHDATA (e.g. Batch_data.h5) with CellProfiler's --get-batch-commands option
# to create a file $FBATCHLIST (e.g. batchlist.txt) with commands to execute.
# Each row of the FBATCHLIST file contains a row with the CP command to process a chunk of images, e.g. 
#
# /opt/local/bin/runcp3.sh -c -r -p Batch_data.h5 -f 1 -l 240
# /opt/local/bin/runcp3.sh -c -r -p Batch_data.h5 -f 241 -l 480
# etc.

$CPBINPATH --plugins-directory $CPPLUGDIR --get-batch-commands $FBATCHDATA |sed -e "s|CellProfiler|${CPBINPATH}|" > $FBATCHLIST

# Step 2
# Create individual jobs in JOBSDIR subfolder (.e.g. slurm.jobs)
# for every line in FBATCHLIST file

nIt=1

# store path to current directory
currDir=`pwd`

# Create subfolders to place various outputs.
# A subfolder to place shell files with slurm jobs
mkdir -p $JOBSDIR

# A subfolder to place the output of slurm
mkdir -p $JOBSDIR.out

# A subfolder to place the output of CP
mkdir -p $OUTDIR

# For every line in $FBATCHLIST file, create a shell file with CP command to execute
while read p; do
	printf -v nItPadded "%04d" $nIt
	currJob=$JOBSDIR/$FJOBCORE$nItPadded.$FJOBEXT
	outDirSeq=$OUTDIR/out_$nItPadded

	echo "#!/bin/sh" > $currJob
	echo "" >> $currJob

	echo "$p --plugins-directory=$CPPLUGDIR -o $outDirSeq -t $TMPDIR" >> $currJob
	nIt=$(( nIt + 1 ))

done <$FBATCHLIST 

chmod a+x $JOBSDIR/$FJOBCORE*

# Step 3
# Create main array submission file ($FARRAY, e.g. arrayjobs.sh)

# Count jobs in slurm.jobs folder
nFILES=`ls -l $JOBSDIR/$FJOBCORE* |wc -l`
echo "Number of tasks = $nFILES"

# Write to array submission file
echo "#!/bin/bash" > $FARRAY
echo "#SBATCH --job-name=cp3" >> $FARRAY
echo "#SBATCH --array=1-$nFILES" >> $FARRAY
echo "#SBATCH --cpus-per-task=1" >> $FARRAY
echo "#SBATCH --mem=$REQMEMPERCPU" >> $FARRAY
echo "#SBATCH --time=$REQTIME" >> $FARRAY
echo "#SBATCH -D $currDir" >> $FARRAY
echo "#SBATCH --output=$JOBSDIR.out/slurm-%A_%a.out" >> $FARRAY
echo "#SBATCH --partition=$SLPART" >> $FARRAY
echo "" >> $FARRAY
echo "arrayfile=\`ls $JOBSDIR/ | awk -v line=\$SLURM_ARRAY_TASK_ID '{if (NR == line) print \$0}'\`" >> $FARRAY
echo "$JOBSDIR/\$arrayfile" >> $FARRAY


# -------------- Submit jobs to the queue ------------------
if [ $TST -eq 1 ]; then
	echo "Test mode ON, jobs were not submitted."
else
	echo "Submitting jobs..."
	sbatch $FARRAY
fi
