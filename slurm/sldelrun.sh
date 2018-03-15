#! /bin/sh
# Delete running jobs in SLURM queue

# Find all the jobs owned by the user
# squeue -u $USERNAME
#
# The output has the following column format:
#             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
#                15     debug job_0003  maciekd PD       0:00      1 (Resources)
#                16     debug job_0004  maciekd PD       0:00      1 (Priority)
#                17     debug job_0005  maciekd PD       0:00      1 (Priority)
#
# Print the Job ID if the state is anything other than complete
# The Username column is checked to skip any header lines
# awk -v username="$USERNAME" '$4 == username && $5 == "R" { print $1 }'
#
# Trim everything after the number part of the Job ID
# cut -d . -f 1
#
# Delete the job id from the queue
# scancel $job_id

    USERNAME=$(whoami)
    echo "Deleting all running jobs owned by $USERNAME"
    for job_id in $(squeue -u $USERNAME | awk -v username="$USERNAME" '$4 == username && $5 == "R" { print $1 }' | cut -d . -f 1); do
        scancel $job_id
    done

