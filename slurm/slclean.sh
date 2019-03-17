#!/bin/bash

# Clean SLURM output, job lists, etc. produced with submission scripts

usage="Error: insufficient arguments!\n
This script by default cleans SLURM-related generated during CellProfiler and LAPtrack runs. Optionally, it can remove intermediate files produced during snalysis.\n
\n
Usage:
$(basename "$0") -options\n
\n
Possible options:\n
	-h | --help		Show this help text.\n
	-t | --test		Test mode: prints all files that would be removed.\n
	-s | --seg		Remove segmented folder; contains segmentation but can be deleted if LAPtrack was also ran and created segmented_over.\n
	-x | --trackxy		Remove track_XY folder with intermediate output from LAPtrack; this is used for extracting single-file images!.\n
	-o | --oneline		Remove 1-line csv.\n
	-z | --gzip             Gzip all csv files\n"
	

# Initialize vars; later may be altered by command-line params
TST=0
SEG=0
XY=0
ONE=0
GZ=0

# read arguments
TEMP=`getopt -o htsxoz --long help,test,seg,trackxy,oneline,gzip -n 'slclean.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
# Tutorial at:
# http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt

while true ; do
	case "$1" in
	-h|--help) echo "$usage"; exit ;;	
	-t|--test) TST=1 ; shift ;;
	-s|--seg)  SEG=1 ; shift ;;
	-x|--trackxy) XY=1 ; shift ;;
	-o|--oneline) ONE=1 ; shift ;;
	-z|--gzip) GZ=1 ; shift ;;
	--) shift ; break ;;
     *) echo "Internal error!" ; exit 1 ;;
    esac
done


if [ $TST -eq 1 ] ; then
	echo "Test mode ON. Files will NOT be removed!"
	echo ""
fi

# Remove SLURM-related files

echo "Removing SLURM-related files"

if [ $TST -eq 0 ] ; then
	find . -name "slurm*" -type d -exec rm -r {} +
else
	find . -name "slurm*" -type d -print
fi

echo ""
FILE="batchlist.txt"
echo "Removing $FILE"
if [ $TST -eq 0 ] ; then
	if [ -f $FILE ] ; then
		rm $FILE
	fi
fi

FILE="arrayjobs.sh"
echo "Removing $FILE"
if [ $TST -eq 0 ] ; then
	if [ -f $FILE ] ; then
		rm $FILE
	fi
fi

if [ $SEG -eq 1 ] ; then
	echo ""
	echo "Removing segmented folders"
	if [ $TST -eq 0 ] ; then
		find . -name "segmented" -type d -exec rm -r {} +
	else
		find . -name "segmented" -type d -print
	fi
fi


if [ $XY -eq 1 ] ; then
	echo ""
	echo "Removing trackXY* folders"
	if [ $TST -eq 0 ] ; then
		find . -name "trackXY_*" -type d -exec rm -r {} +
	else
		find . -name "trackXY_*" -type d -print
	fi
fi


if [ $ONE -eq 1 ] ; then
	echo ""
	echo "Removing 1-line csv intermediate files"
	if [ $TST -eq 0 ] ; then
		find . -name "*_1line.csv" -type f -exec rm {} +
	else
		find . -name "*_1line.csv" -type f -print
	fi
fi


if [ $GZ -eq 1 ] ; then
	echo ""
	echo "GZipping all csv files"
	if [ $TST -eq 0 ] ; then
		find . ! -name "lapconfig.csv" -name "*.csv" -type f -exec gzip {} +
	else
		find . ! -name "lapconfig.csv" -name "*.csv" -type f -print
	fi
fi

