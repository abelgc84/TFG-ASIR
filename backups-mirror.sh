#! /bin/bash

#############################################################################################################
#
# Variables globales.
#
#############################################################################################################

fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/$USER"
configEspejo="$backupDestino/backups-espejo.conf"

#############################################################################################################
#
# Funciones del script.
#
#############################################################################################################

#################################################
# extraerNombre
# Extrae el nombre de un archivo o directorio de una ruta absoluta
# Parámetros:
#   $1: Ruta absoluta del archivo o directorio
# Salida:
#   Nombre del archivo o directorio
#################################################
extraerNombre () {
    ruta=$1
    nombre="$(basename "$ruta")"
    echo $nombre
}

#################################################
# verificarDirectorioMirror
# Verifica si el directorio espejo existe, si no existe lo crea
# Parámetros:
#   $1: Nombre del directorio
#################################################
verificarDirectorioMirror () {
    if [ ! -d "$backupDestino/$1" ]; then
        mkdir -p "$backupDestino/$1"
    fi
}

#################################################
# recorrerDirectorio
# Recorre un directorio y crea una copia espejo de los archivos y directorios
# Parámetros:
#   $1: Directorio a recorrer
#################################################
recorrerDirectorio () {
    for fichero in $1/*; do

        if [ -f "$fichero" ]; then
            # Dividimos la ruta en partes tomando como separador (-F) el directorio espejo
            archivo=$(echo $fichero|awk -F"$directorio/" '{print $2}')
            if [ ! -f "$backupDestino/$directorio/$archivo" ]; then
                cp $fichero $backupDestino/$directorio
                echo "$fichero $backupDestino/$directorio">>$HOME/backup.log
            else
                diff $fichero $backupDestino/$directorio/$archivo
                if [ $? -ne 0 ]; then
                    cp $fichero $backupDestino/$directorio
                    echo "$fichero $backupDestino/$directorio">>$HOME/backup.log
                fi
            fi
        elif [ -d "$fichero" ]; then
            echo "directorio: $fichero"
            recorrerDirectorio $fichero
        fi

    done
}

#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

# while true; do

    while read -r linea; do
        directorio=$(extraerNombre $linea)
        verificarDirectorioMirror $directorio
        recorrerDirectorio $linea
    done<$configEspejo

# done