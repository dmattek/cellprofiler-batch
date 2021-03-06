# Scripts for CellProfiler batch processing

Author           : Maciej Dobrzynski

Date created     : 20171205

File description:

* Directory `pbs` contains scripts for submitting CP jobs to PBS queueing system
	- `submitCP2PBS.sh` - bash script processes `Batch_data.h5`, which is the output of CP's **CreateBatchFiles** module. The script submits jobs to the PBS queueing system. Every job corresponds to a group created in **Groups** module. Execute the script in the folder with `Batch_data.h5` file.

* Directory `slurm` contains scripts for submitting CP jobs to SLURM queueing system

* Directory `misc`
	- `cat2lineHeader.sh` - bash script to convert a csv file with a two-line header to a single-line header. A csv with a double-header is often output by CellProfiler when measurements of multiple objects are placed in a single file, or when metadata is added to an object file. 


Tested on:
Ubuntu 18.04.2 LTS
CellProfiler 2.3.1
CellProfiler 3.0.0