#! /bin/bash

#############################################################################################################
#
# Variables globales.
#
#############################################################################################################

fechaActual=$(date +"%Y%m%d")
configEspejo="/backup/config/backups-espejo.conf"

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
# recorrerDirectorio
# Recorre un directorio y crea una copia espejo de los archivos y directorios
# Parámetros:
#   $1: Directorio a recorrer
#   $2: Directorio espejo o subdirectorios del directorio espejo en caso de recursividad
#################################################
recorrerDirectorio () {
    for fichero in $1/*; do

        if [ -f "$fichero" ]; then    
            # Dividimos la ruta en partes tomando como separador (-F) el directorio espejo
            archivo=$(echo $fichero|awk -F"$2/" '{print $2}')
            if [ ! -f "$backupDestino/$2/$archivo" ]; then
                cp $fichero $backupDestino/$2
                copia=$(extraerNombre $fichero)
                chown $usuario:$usuario $backupDestino/$2/$copia
            else
                diff $fichero $backupDestino/$2/$archivo
                if [ $? -ne 0 ]; then
                    copia=$(extraerNombre $fichero)
                    cp $fichero $backupDestino/$copia
                fi
            fi
        elif [ -d "$fichero" ]; then
            subdirectorio=$(extraerNombre $fichero)
            if [ ! -d "$backupDestino/$2/$(extraerNombre $fichero)" ]; then
                mkdir -p "$backupDestino/$2/$(extraerNombre $fichero)"
                chown $usuario:$usuario "$backupDestino/$2/$(extraerNombre $fichero)"
                recorrerDirectorio $fichero "$2/$subdirectorio"
            else
                recorrerDirectorio $fichero "$2/$subdirectorio"
            fi
        fi

    done
}

#################################################
# recorrerEspejo
# Recorre el directorio espejo y comprueba que los archivos y directorios existan en el directorio original
# Parámetros:
#   $1: Directorio espejo  
#   $2: Directorio original o subdirectorios del directorio original en caso de recursividad
#################################################
recorrerEspejo () {
    for fichero in $1/*; do

        if [ -f "$fichero" ]; then
            archivo=$(extraerNombre $fichero)
            if [ ! -f "$2/$archivo" ]; then
                rm -f $fichero
            fi
        elif [ -d "$fichero" ]; then
            directorio=$(extraerNombre $fichero)
            if [ ! -d "$2/$directorio" ]; then
                rm -rf $fichero
            else
                recorrerEspejo $fichero $2/$directorio
            fi
        fi

    done
}

#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

while true; do

    while IFS=: read -r usuario ruta; do

        backupDestino="/backup/$usuario"
        directorio=$(extraerNombre $ruta)
        if [ ! -d "$backupDestino" ]; then
            mkdir -p "$backupDestino"
            chown $usuario:$usuario "$backupDestino"
        fi
        # Verificamos si el directorio espejo existe, si no existe lo creamos
        if [ ! -d "$backupDestino/$directorio" ]; then
            mkdir -p "$backupDestino/$directorio"
            chown $usuario:$usuario "$backupDestino/$directorio"
        fi
        recorrerDirectorio $ruta $directorio
        recorrerEspejo $backupDestino/$directorio $ruta

    done<$configEspejo

done