#! /bin/bash

# Script para montar un recurso NFS

# Variables
nfs_server="10.0.2.5:/backup"
punto_montaje="/backup"

while true; do

    if [ ! -d $punto_montaje ]; then
        mkdir $punto_montaje
    fi

    df -h|grep $nfs_server>/dev/null

    if [ $? -ne 0 ]; then
        mount $nfs_server $punto_montaje
    fi

done