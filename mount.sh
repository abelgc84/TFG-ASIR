#! /bin/bash

# Script para montar un recurso NFS

nfs_server="10.0.2.5:/backup"
punto_montaje="/backup"

while true; do

    df -h|grep $nfs_server>/dev/null

    if [ $? -ne 0 ]; then
        mount $nfs_server $punto_montaje
    fi

done