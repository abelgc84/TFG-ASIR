#! /bin/bash

#############################################################################################################
# Descripción: Script para hacer copias de seguridad de los archivos indicados en /backup/backup-home.conf
# Autor: Abel Gijón Cordero
# Versión: 2.0
# Fecha: 2024-03-24
# Licencia: GPL
#############################################################################################################

#############################################################################################################
#
# Variables globales.
#
#############################################################################################################

fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/home"
configHome="/backup/config/backups-home.conf"

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
# extraerRuta
# Extrae la ruta absoluta del directorio home de un usuario
# Parámetros:
#   $1: Nombre de usuario
# Salida:
#   Ruta absoluta del directorio home
#################################################
extraerRuta () {
    usuario=$1
    ruta=$(eval echo ~$usuario)
    echo $ruta
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
# copiaSeguridadCompleta
# Realiza una copia de seguridad completa de un archivo o directorio
#################################################
copiaSeguridadCompleta () {
    nombre=home
    destino="$backupDestino/$fechaActual-$usuario-$grupo-$nombre"
    tar -czf "$destino".tar.gz $fichero
}
#################################################
# eliminarCopiasAntiguas
# Elimina las copias antiguas de un usuario
#################################################
eliminarCopiasAntiguas () {
    numCopiasActuales=$(ls $backupDestino|grep $usuario|wc -l)
        if [ $numCopiasActuales -gt $numCopias ]; then
            copiasEliminar=$((numCopiasActuales - numCopias))
            ls -t $backupDestino|grep $usuario|tail -1|rm
        fi
}

#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

while true; do

    # Eliminamos las líneas en blanco del fichero de configuración.
    eliminarLineasBlanco $configHome

    # Iteramos sobre el fichero de configuración.
    while IFS=: read usuario grupo numCopias numDias; do
        
        # Comprobamos si el directorio de destino existe.
        if [ ! -d $backupDestino ]; then
            mkdir -p $backupDestino
        fi

        # Extraemos la ruta absoluta del directorio home del usuario.
        fichero=$(extraerRuta $usuario)
#echo "Fichero: $fichero"
        # Contamos el número de copias que hay.
        numCopiasActuales=$(ls $backupDestino|grep $usuario|wc -l)

        # Realizamos la primera copia en caso de no tener ninguna.
        if [ $numCopiasActuales -eq 0 ]; then
            copiaSeguridadCompleta
        fi

        # Calculamos los días que han pasado desde la última copia.
        ultimaCopia=$(ls -t $backupDestino|grep $usuario|head -1)
        fechaUltimaCopia=$(echo $ultimaCopia|cut -d '-' -f 1)
        diasTranscurridos=$((($(date +%s) - $(date -d $fechaUltimaCopia +%s)) / 86400))
#echo "diasTranscurridos: $diasTranscurridos"
        # Realizamos la copia si han pasado los días indicados.
        if [ $diasTranscurridos -ge $numDias ]; then
            copiaSeguridadCompleta
        fi

        # Comprobamos si hay que eliminar copias antiguas.
        eliminarCopiasAntiguas        

    done < $configHome

done

