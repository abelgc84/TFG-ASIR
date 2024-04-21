#! /bin/bash

#############################################################################################################
#
# Daemon para realizar copias de seguridad de los archivos de configuración del sistema.
#
#############################################################################################################

#############################################################################################################
#
# Variables globales.
# 
#############################################################################################################

fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/etc"
configEtc="/backup/config/backups-etc.conf"

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
# copiaSeguridadCompleta
# Realiza una copia de seguridad completa de un archivo o directorio
# Parámetros:
#   $1: Ruta del archivo o directorio
#################################################
copiaSeguridadCompleta () {
    usuario=$(stat -c "%U" $fichero)
    grupo=$(stat -c "%G" $fichero)
    nombre=$nombreFichero
    destino="$backupDestino/$fechaActual-$usuario-$grupo-$nombre"
    sudo tar -czf "$destino".tar.gz $fichero
}

#################################################
# eliminarCopiasAntiguas
# Elimina las copias antiguas de un archivo o directorio
# Parámetros:
#   $1: Ruta del archivo o directorio
#################################################
eliminarCopiasAntiguas () {
    numCopiasActuales=$(ls $backupDestino|grep $nombreFichero| wc -l)
    if [ $numCopiasActuales -gt $numCopias ]; then
        copiaEliminar=$(ls -t $backupDestino|grep $nombreFichero|tail -1)
        rm -f $backupDestino/$copiaEliminar
    fi 
}

#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

while true; do

    # Eliminamos las líneas en blanco del fichero de configuración.
    eliminarLineasBlanco $configEtc

    # Iteramos sobre el fichero de configuración.
    while IFS=: read fichero numCopias numDias; do

        # Comprobamos si el directorio de destino existe.
        if [ ! -d $backupDestino ]; then
            mkdir -p $backupDestino
        fi

        nombreFichero=$(echo $fichero|tr '/' '_')
        # Contamos el número de copias que hay.
        numCopiasActuales=$(ls $backupDestino|grep $nombreFichero|wc -l)
        # Realizamos la primera copia en caso de no tener ninguna.
        if [ $numCopiasActuales -eq 0 ]; then
            copiaSeguridadCompleta
        fi

        # Calculamos los días que han pasado desde la última copia.
        ultimaCopia=$(ls -t $backupDestino|grep $nombreFichero|head -1)
        fechaUltimaCopia=$(echo $ultimaCopia|cut -d'-' -f1)
        diasTranscurridos=$((($(date +%s) - $(date -d $fechaUltimaCopia +%s)) / 86400))
        # Realizamos la copia si han pasado los días indicados.
        if [ $diasTranscurridos -ge $numDias ]; then
            copiaSeguridadCompleta
        fi

        # Comprobamos si hay que eliminar copias antiguas.
        eliminarCopiasAntiguas

    done < $configEtc
done