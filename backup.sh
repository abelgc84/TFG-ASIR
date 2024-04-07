#! /bin/bash

#############################################################################################################
# Descripción: Script para realizar copias de seguridad de archivos y directorios en Linux con Zenity.
# Autor: Abel Gijón Cordero
# Versión: 2.0
# Fecha: 2024-03-24
# Licencia: GPL
#############################################################################################################

# Comprobación de los permisos del usuario para lanzar el script adecuado.
# Si el usuario es administrador, se lanza el script backupAdm.sh. Si no, se lanza el script backupUsr.sh.
if [ $USER = "root" ] || [ `cat /etc/group|grep sudo|grep $USER` ]; then
    permisos="administrador"
    backupAdm.sh $permisos
else
    permisos="usuario"
    backupUsr.sh $permisos
fi