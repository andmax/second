#!/bin/bash
# @file status_slurm.sh
# @brief Script to check status of slurm
# @author Andre Maximo
# @date May, 2020
# @copyright The MIT License

if [[ $(ps aux | grep -E "slurmctld|slurmd" | grep -vc grep) > 0 ]]
then
  scontrol -o show nodes
  sinfo -o "%23N %10c %10m %20C %33G %10A %25E"
  squeue -o  "%.18i %.9P %.16j %.8u %.2t %.10M %.6D %23R %8C %33b"
else
    echo "SLURM is not running"
fi

