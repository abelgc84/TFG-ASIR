#! /bin/bash

#############################################################################################################
# Descripción: Script para realizar copias de seguridad de archivos y directorios en Linux con Zenity.
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

salida=0

#############################################################################################################
#
# Funciones del script.
#
#############################################################################################################

#################################################
# mostrarMenu
# Muestra un menú con Zenity con dos columnas
# Parámetros:
#   $1: Título del menú
#   $2: Título de la primera columna
#   $3: Título de la segunda columna
#   $@: Elementos del menú
#################################################
mostrarMenu () {
    titulo="$1"
    shift
    columna1="$1"
    shift
    columna2="$1"
    shift
    zenity --title "$titulo" \
           --width="600" \
           --height="500" \
           --list \
           --column "$columna1" \
           --column "$columna2" \
           "$@"
}

#################################################
# seleccionarArchivo
# Muestra una ventana de selección de archivos con Zenity
# Salida:
#   Lista de archivos seleccionados separados por espacios
#################################################
seleccionarArchivo () {
    zenity --title="Selecciona archivos" \
        --file-selection \
        --multiple \
        --separator=" "
}

#################################################
# seleccionarDirectorio
# Muestra una ventana de selección de directorios con Zenity
# Salida:
#   Lista de directorios seleccionados separados por espacios
#################################################
seleccionarDirectorio () {
    zenity --title="Selecciona un directorio" \
        --file-selection \
        --multiple \
        --separator=" " \
        --directory
}

#################################################
# mostrarMensaje
# Muestra un mensaje con Zenity
# Parámetros:
#   $1: Mensaje a mostrar
#################################################
mostrarMensaje () {
    zenity --info \
        --width="600" \
        --text="$1"
}

#################################################
# mostrarError
# Muestra un mensaje de error con Zenity
# Parámetros:
#   $1: Mensaje de error
#################################################
mostrarError () {
    zenity --error \
        --width="600" \
        --text="$1"
}

#################################################
# preguntar
# Muestra una pregunta con Zenity
# Parámetros:
#   $1: Pregunta
# Salida:
#   0: Si se pulsa el botón Aceptar
#   1: Si se pulsa el botón Cancelar
#################################################
preguntar () {
    zenity --question \
        --width="600" \
        --text="$1"
}


#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

# Menú para usuarios
main=$(mostrarMenu "Copia de seguridad para usuarios" \
    "Opción" "Descripción" \
    "1" "Realizar copia de seguridad completa" \
    "2" "Configurar copias de seguridad incrementales" \
    "3" "Configurar directorio espejo" \
    "4" "Restaurar copias de seguridad" \
    "5" "Salir")

if [ $? -eq 0 ]; then
    case $main in
    1)  # Realizar copia de seguridad completa
        
        menu=$(mostrarMenu "Realizar copia de seguridad completa" \
            "Opción" "Descripción" \
            "1" "Seleccionar archivos" \
            "2" "Seleccionar directorios" \
            "3" "Salir")

        if [ $? -eq 0 ]; then
            case $menu in
            1)  # Seleccionar archivos
                
                echo "Seleccionar archivos"
            ;;
            2)  # Seleccionar directorios
                
                echo "Seleccionar directorios"
            ;;
            3)  # Salir
                
                salida=1
            ;;
            esac
        fi
    ;;
    2)  # Configurar copias de seguridad incrementales
        
        menu=$(mostrarMenu "Configurar copias de seguridad incrementales" \
            "Opción" "Descripción" \
            "1" "Crear nueva configuración" \
            "2" "Modificar configuración" \
            "3" "Eliminar configuración" \
            "4" "Salir")

        if [ $? -eq 0 ]; then
            case $menu in
            1)  # Crear nueva configuración
                
                echo "Crear nueva configuración"
            ;;
            2)  # Modificar configuración
                
                echo "Modificar configuración"
            ;;
            3)  # Eliminar configuración
                
                echo "Eliminar configuración"
            ;;
            4)  # Salir
                
                salida=1
            ;;
            esac
        fi
    ;;
    3)  # Configurar directorio espejo
        
        menu=$(mostrarMenu "Configurar directorio espejo" \
            "Opción" "Descripción" \
            "1" "Añadir directorio espejo" \
            "2" "Eliminar directorio espejo" \
            "3" "Salir")

        if [ $? -eq 0 ]; then
            case $menu in
            1)  # Añadir directorio espejo
                
                echo "Añadir directorio espejo"
            ;;
            2)  # Eliminar directorio espejo
                
                echo "Eliminar directorio espejo"
            ;;
            3)  # Salir
                
                salida=1
            ;;
            esac
        fi
    ;;
    4)  # Resturar copias de seguridad
        
        menu=$(mostrarMenu "Restaurar copias de seguridad" \
            "Opción" "Descripción" \
            "1" "Restaurar copias de seguridad completas" \
            "2" "Restaurar copias de seguridad incrementales" \
            "3" "Salir")

        if [ $? -eq 0 ]; then
            case $menu in
            1)  # Restaurar copias de seguridad completas
                
                echo "Restaurar copias de seguridad completas"
            ;;
            2)  # Restaurar copias de seguridad incrementales
                
                echo "Restaurar copias de seguridad incrementales"
            ;;
            3)  # Salir
                
                salida=1
            ;;
            esac
        fi
    ;;
    5) # Salir
    
        salida=1
    ;;
    esac
else
    salida=1
fi