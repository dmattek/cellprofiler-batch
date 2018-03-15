# Scripts for CellProfiler batch processing

Author           : Maciej Dobrzynski

Date created     : 20171205

File description:

- submitCP2PBS.sh - bash script that processes the output of CP's **CreateBatchFiles** module *Batch_data.h5* and submits jobs to the PBS queueing system. Every job corresponds to a group created in **Groups** module. Execute the script in the folder with Batch_data.h5 file.

- cat2lineHeader.sh - bash script to convert a csv file with a two-line header to a single-line header. A csv with a double-header is often output by CellProfiler when measurements of multiple objects are placed in a single file, or when metadata is added to an object file. 

- cp2ubuntu.def and cp3ubuntu.def - recipes to create singularity containers for CP2 and 3, respectively.

Tested on:
Ubuntu 16.04.2 LTS
CellProfiler 2.2.0 (rev ac0529e)
