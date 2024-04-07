#! /bin/bash

#############################################################################################################
#
# Variables globales.
# 
#############################################################################################################

salida=0

#############################################################################################################
# 
# Funciones del script.
# Incluimos el archivo funciones.sh 
#
#############################################################################################################

source funciones.sh

#############################################################################################################
#
# Cuerpo del script.
#
#############################################################################################################

while [ $salida -eq 0 ]; do
    if [ -n "$1" ] && [ "$1" == "usuario" ]; then

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
    else
        error=$(echo -e "No se ha podido realizar la comprobación de permisos. \nEjecute backup.sh para utilizar la aplicación.")
        mostrarError "$error"
        salida=1
    fi
done