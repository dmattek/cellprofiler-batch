#!/bin/bash

########################################################################
#
# Script  name      : cat2lineHeader.sh
#
# Author            : Maciej Dobrzynski
#
# Contact           : macdobry [at] gmail [dot] com
#
# Date created      : 20180228
#
# Purpose           : concatenate a two-line header by column 
#
# Result            : Converts the input file:
#					A, A, B, B, B
#					a, b, c, d, e
#					1, 2, 3, 4, 5
#					6, 7, 8, 9, 0
#
#					To:
#					A_a, A_b, B_c, B_d, B_e
#					1,   2,   3,   4,   5
#					6,   7,   8,   9,   0
#
# Example usage     : cat2lineHeader.sh -i ", " -o "-" test.txt
# 
# Tested on:
# Ubuntu 16.04.2 LTS
# OSX 10.11.6 (Darwin Kernel Version 16.7.0)
########################################################################

usage="This script concatenates two-line column headers 

Usage:
$(basename "$0") [-h] [-i char] [-o char] filename

where:
	-h | --help		Show this Help text.
	-c | --conveol	Convert EOL from DOS (CRLF line terminators) to UNIX format (LF only).
	-i | --sepin	String with the separator in the input file (default ",").
	-o | --sepout 	String with the separator in the output file (default "_"),
	-t | --test		Test mode. Unused..."
	

# separator in the input file, e.g. a comma
FSEP=","

# separator for concatenated column name sin the output file, e.g. an underscore
OSEP="_"

# Flag for test mode
TST=0

# Flag for conversion
CONV=0

# read arguments
TEMP=`getopt -o thci:o: --long test,help,conveol,sepin:,sepout: -n 'cat2lineHeader.sh' -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
# Tutorial at:
# http://www.bahmanm.com/blogs/command-line-options-how-to-parse-in-bash-using-getopt

while true ; do
    case "$1" in
        -t|--test) TST=1 ; shift ;;
        -h|--help) echo "$usage"; exit ;;
        -c|--conveol) CONV=1 ; shift ;;
        -i|--sepin)
            case "$2" in
                "") shift 2 ;;
                *) FSEP=$2 ; shift 2 ;;
            esac ;;
        -o|--sepout)
            case "$2" in
                "") shift 2 ;;
                *) OSEP=$2 ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done


# Based on:
# https://stackoverflow.com/questions/49015142/concatenate-two-line-header-by-column/49015941#49015941

argfile=$1

# convert end of line 
if [ $CONV -eq 1 ]; then
	dos2unix $argfile
fi

line1=($(sed -n "1s/${FSEP}/ /gp" $argfile))
line2=($(sed -n "2s/${FSEP}/ /gp" $argfile))
line12=()

for ((i=0; i<${#line1[*]}-1; i++))
do
    line12+=${line1[$i]}$OSEP${line2[$i]}$FSEP
done
line12+=${line1[$i]}$OSEP${line2[$i]}


# remove last comma
echo $line12
sed -n '3,$p' $argfile

#awk -v par1="$FSEP" -v par2="$OSEP" 'BEGIN{ FS = OFS = par1 }
#     NR == 1{ split($0, a, par1); next }
#     NR == 2{ for(ii=1; ii <= NF; ii++) $ii = a[ii]par2$ii }1' $1
	 
	 