#!/bin/bash
# @file stop_slurm.sh
# @brief Script to stop slurm
# @author Andre Maximo
# @date May, 2020
# @copyright The MIT License

ps aux | grep slurm | awk '{print $2}' | xargs sudo kill -9
