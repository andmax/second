#!/bin/bash
# @file status_slurm.sh
# @brief Script to check status of slurm
# @author Andre Maximo
# @date May, 2020
# @copyright The MIT License

if [[ $(ps aux | grep -E "slurmctld|slurmd" | grep -vc grep) > 0 ]]
then
    seq -s . 120|tr -d '[:digit:]'
    scontrol -o show nodes
    seq -s . 120|tr -d '[:digit:]'
    sinfo -o "%23N %10c %10m %20C %33G %10A %25E"
    seq -s . 120|tr -d '[:digit:]'
    squeue -o  "%.5i %.9P %.9j %.8u %.2t %.6M %.5D %23R %4C %10m %29b"
    if [ $UID -eq 0 -o $UID -eq 505 ]
    then
        seq -s . 120|tr -d '[:digit:]'
        sudo sacct --format=jobid,jobname,user,account,partition,ntasks,alloccpus,elapsed,state,exitcode
    fi
else
    echo "SLURM is not running"
fi
