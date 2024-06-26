#! /bin/bash

#############################################################################################################
#
# Variables globales.
# 
#############################################################################################################

salida=0
fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/$USER"
configEspejo="/backup/config/backups-espejo.conf"

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
            "2" "Configurar directorio espejo" \
            "3" "Restaurar copias de seguridad" \
            "4" "Eliminar copias de seguridad" \
            "5" "Salir")

        if [ $? -eq 0 ]; then
            case $main in
            1)  
                # Realizar copia de seguridad completa
                
                menu=$(mostrarMenu "Realizar copia de seguridad completa" \
                    "Opción" "Descripción" \
                    "1" "Seleccionar archivos" \
                    "2" "Seleccionar directorios" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  
                        # Seleccionar archivos
                        
                        cd $HOME
                        archivos=$(seleccionarArchivo)
                        cd ->/dev/null
                        copiaSeguridadCompleta $archivos
                    ;;
                    2)  
                        # Seleccionar directorios
                        
                        cd $HOME
                        directorios=$(seleccionarDirectorio)
                        cd ->/dev/null
                        copiaSeguridadCompleta $directorios
                    ;;
                    3)  
                        # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;            
            2)  
                # Configurar directorio espejo
                
                menu=$(mostrarMenu "Configurar directorio espejo" \
                    "Opción" "Descripción" \
                    "1" "Añadir directorio espejo" \
                    "2" "Eliminar directorio espejo" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  
                        # Añadir directorio espejo
                        
                        cd $HOME
                        directorio=$(seleccionarDirectorio)
                        cd ->/dev/null
                        anadirDirectorioEspejo $directorio
                    ;;
                    2)  
                        # Eliminar directorio espejo
                        
                        directorio=$(mostrarDirectoriosEspejo)
                        if [ $? -eq 0 ]; then
                            eliminarDirectorioEspejo $directorio
                        fi
                    ;;
                    3)  
                        # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;
            3)  
                # Resturar copias de seguridad
                
                copia=$(mostrarCopiasSeguridadCompleta)
                if [ $? -eq 0 ]; then
                    restaurarCopiaSeguridadCompleta $copia
                fi
            ;;
            4) 
                # Eliminar copias de seguridad
            
                copia=$(mostrarCopiasSeguridadCompleta)
                if [ $? -eq 0 ]; then
                    rm $backupDestino/$copia
                fi
            ;;
            5)  
                # Salir
                
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