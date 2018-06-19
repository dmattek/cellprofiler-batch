#!/bin/bash

# Create and submit CellProfiler jobs to SLURM queue
# Jobs are generated based on h5 file (typically Batch_data.h5) created with CreateBatchFile module of CellProfiler
# The script should be execute IN the directory with h5 file

usage="Error: insufficient arguments!\n
This script processes CellProfiler batch h5 file, creates jobs, and submits to SLURM queue\n
\n
Usage:
$(basename "$0") -options H5-batch-file-from-CP\n
\n
Possible options:\n
	-h | --help		Show this help text.\n
	-t | --test		Test mode: creates all intermediate files without submitting to a queue.\n
	-c | --cpbin		Path to CellProfiler binary (default \$USERHOMEDIR/.local/bin/cellprofiler).\n
	-i | --cpinst		Path to CellProfiler install directory (default \$USERHOMEDIR/CellProfiler).\n
	-m | --tmpdir		Path to TEMP directory (default /tmp/cp3).\n
	-o | --outdir		Directory with CP output.\n"
	
E_BADARGS=85

if [ ! -n "$1" ]
then
  echo -e $usage 
  exit $E_BADARGS
fi  


# Definitions
# User home directory
USERHOMEDIR=`eval echo "~$USER"`

# Directory with CellProfiler install 
CPINSTDIR=/opt/local/cellprofiler

# Path to CellProfiler binary
CPBINPATH=/opt/local/bin/runcp2cont.sh

# Name of the file with commands to execute
FBATCHLIST=batchlist.txt

# Name of the directory to store jobs for submission
JOBSDIR=slurm.jobs

# Name of the directory to store temporary files
TMPDIR=/tmp

# Name of the directory to store CP output
OUTDIR=output

# Prefix for naming job files
FJOBCORE="job_"

# Suffix for job files
FJOBEXT=sh

# Test mode switch
TST=0


# read arguments
TEMP=`getopt -o thc:i:m:o: --long test,help,cpbin:,cpinst:,tmpdir:outdir: -n 'slsubarrcp2.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
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
	--) shift ; break ;;
     *) echo "Internal error!" ; exit 1 ;;
    esac
done

# Name of the h5 file generated ith CreateBatchFile module of CP
FBATCHDATA=$1

# CP plugins directory
CPPLUGDIR=$CPINSTDIR/plugins


# CPcreateBatch.bat
# Create a file with list of commands to execute
$CPBINPATH --plugins-directory $CPPLUGDIR --get-batch-commands $FBATCHDATA |sed -e "s|CellProfiler|${CPBINPATH}|" > $FBATCHLIST

# PBScreateJobs.bat
# Parse FBATCHLIST file and create individual jobs in JOBSDIR

nIt=1

currDir=`pwd`
mkdir -p $JOBSDIR
mkdir -p $JOBSDIR.out
mkdir -p $OUTDIR

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

# Submit to SLURM queue
nFILES=`ls -l $JOBSDIR/$FJOBCORE* |wc -l`
echo "Number of tasks = $nFILES"

# create a file with job array for submission
FARRAY=arrayjobs.sh

echo "#!/bin/bash" > $FARRAY
echo "#SBATCH --array=1-$nFILES" >> $FARRAY
echo "#SBATCH --mem-per-cpu=4096" >> $FARRAY
echo "#SBATCH -D $currDir" >> $FARRAY
echo "#SBATCH --output=$JOBSDIR.out/slurm-%A_%a.out" >> $FARRAY
echo "" >> $FARRAY
echo "arrayfile=\`ls $JOBSDIR/ | awk -v line=\$SLURM_ARRAY_TASK_ID '{if (NR == line) print \$0}'\`" >> $FARRAY
echo "$JOBSDIR/\$arrayfile" >> $FARRAY

# submit jobs to a queue
if [ $TST -eq 1 ]; then
	echo "Test mode ON, jobs were not submitted."
else
	echo "Submitting jobs..."
	sbatch $FARRAY
fi
