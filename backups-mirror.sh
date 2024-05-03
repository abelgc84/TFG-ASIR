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
# eliminarLineasBlanco
# Función para eliminar las líneas en blanco del fichero de configuración.
# Parámetros:
#   $1: Fichero de configuración.
#################################################
eliminarLineasBlanco() {
    sed -i '/^$/d' "$1"
}

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
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Copiado: $2/$archivo" >> /backup/config/backups-espejo.log
                copia=$(extraerNombre $fichero)
                chown $usuario:$usuario $backupDestino/$2/$copia
            else
                diff $fichero $backupDestino/$2/$archivo
                if [ $? -ne 0 ]; then
                    copia=$(extraerNombre $fichero)
                    cp $fichero $backupDestino/$copia
                    echo "$(date "+%Y %b %d %H:%M:%S") $usuario Copiado: $2/$archivo" >> /backup/config/backups-espejo.log
                fi
            fi
        elif [ -d "$fichero" ]; then
            subdirectorio=$(extraerNombre $fichero)
            if [ ! -d "$backupDestino/$2/$(extraerNombre $fichero)" ]; then
                mkdir -p "$backupDestino/$2/$(extraerNombre $fichero)"
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Creado: $2/$(extraerNombre $fichero)" >> /backup/config/backups-espejo.log
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
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Eliminado: $fichero" >> /backup/config/backups-espejo.log
            fi
        elif [ -d "$fichero" ]; then
            directorio=$(extraerNombre $fichero)
            if [ ! -d "$2/$directorio" ]; then
                rm -rf $fichero
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Eliminado: $fichero" >> /backup/config/backups-espejo.log
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

    if [ $(stat -c %a $configEspejo) -ne 777 ]; then
        chmod 777 $configEspejo
    fi
    # Eliminamos las líneas en blanco del fichero de configuración.
    eliminarLineasBlanco $configEspejo

    while IFS=: read -r usuario ruta; do

            backupDestino="/backup/$usuario"
            directorio=$(extraerNombre $ruta)
            if [ ! -d "$backupDestino" ]; then
                mkdir -p "$backupDestino"
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Creado: $backupDestino" >> /backup/config/backups-espejo.log
                chown $usuario:$usuario "$backupDestino"
            fi
            # Verificamos si el directorio espejo existe, si no existe lo creamos
            if [ ! -d "$backupDestino/$directorio" ]; then
                mkdir -p "$backupDestino/$directorio"
                echo "$(date "+%Y %b %d %H:%M:%S") $usuario Creado: $backupDestino/$directorio" >> /backup/config/backups-espejo.log
                chown $usuario:$usuario "$backupDestino/$directorio"
            fi
            recorrerDirectorio $ruta $directorio
            recorrerEspejo $backupDestino/$directorio $ruta

    done<$configEspejo

done