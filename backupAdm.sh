#! /bin/bash

#############################################################################################################
#
# Variables globales.
# 
#############################################################################################################

salida=0
fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/$USER"
backupHome="/backup/home"
backupEtc="/backup/etc"
configHome="/backup/config/backups-home.conf"
configEtc="/backup/config/backups-etc.conf"

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

# Comprobación de los permisos del usuario
if [ $USER = "root" ]; then
    permisos="administrador"
else
    cat /etc/group|grep sudo|grep $USER>/dev/null
    if [ $? -eq 0 ]; then
        permisos="administrador"
    else
        permisos="usuario"
    fi
fi

while [ $salida -eq 0 ]; do
    if [ $permisos = "administrador" ]; then

        main=$(mostrarMenu "Copia de seguridad para administración" \
            "Opción" "Descripción" \
            "1" "Configurar copias de seguridad de los directorios de trabajo" \
            "2" "Configurar copias de seguridad de archivos de configuración" \
            "3" "Acceder a la configuración de copias de seguridad" \
            "4" "Restaurar copias de seguridad" \
            "5" "Borrar copias de seguridad" \
            "6" "Aplicación para usuarios" \
            "7" "Salir")

        if [ $? -eq 0 ]; then
            case $main in
            1)  # Configuración de copias de seguridad de los directorios de trabajo
                
                menu=$(mostrarMenu "Configuración de copias de seguridad de los directorios de trabajo" \
                    "Opción" "Descripción" \
                    "1" "Configurar copias de seguridad para usuario" \
                    "2" "Configurar copias de seguridad para grupos" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  # Configuración de copias de seguridad para usuario
                        
                        usuarios=$(mostrarUsuarios)
                        # Iteramos sobre los usuarios seleccionados
                        for usuario in $usuarios; do
                            # Verificamos si el usuario tiene una configuración previa.
                            cat $configHome|grep $usuario:>/dev/null
                            if [ $? -eq 0 ]; then
                                mensaje=$(echo "El usuario $usuario ya tiene una configuración previa")
                                mostrarMensaje "$mensaje"
                            else
                                mostrarMensaje "Introduzca la configuración de copias de seguridad para el usuario $usuario"
                                configuracion=$(configurarCopiasSeguridad)
                                if [ $? -eq 0 ]; then
                                    # Verificamos que la configuración no sea nula
                                    if [ ! -z $configuracion ]; then
                                        verificarDirectorioConfiguracion
                                        # Guardamos la configuración en $configHome. Estructura; usuario:grupo:numCopias:numDias
                                        echo "$usuario:$usuario:$configuracion" >> $configHome
                                    fi
                                fi
                            fi
                        done
                    ;;
                    2)  # Configuración de copias de seguridad para grupos
                        
                        grupos=$(mostrarGrupos)                   
                        # Iteramos sobre los grupos seleccionados
                        for grupo in $grupos; do
                            # Verificamos si el grupo tiene una configuración previa.
                            cat $configHome|grep :$grupo:>/dev/null
                            if [ $? -eq 0 ]; then
                                mensaje=$(echo "El grupo $grupo ya tiene una configuración previa")
                                mostrarMensaje "$mensaje"
                            else
                                mostrarMensaje "Introduzca la configuración de copias de seguridad para el grupo $grupo"
                                configuracion=$(configurarCopiasSeguridad)
                                if [ $? -eq 0 ]; then
                                    usuarios=$(extraerUsuarios $grupo)
                                    # Iteramos sobre los usuarios del grupo
                                    for usuario in $usuarios; do                                
                                        verificarDirectorioConfiguracion
                                        # Guardamos la configuración en $configHome. Estructura; usuario:grupo:numCopias:numDias
                                        echo "$usuario:$grupo:$configuracion" >> $configHome
                                    done
                                fi
                            fi
                        done
                    ;;
                    3)  # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;
            2)  # Configuración de copias de seguridad de archivos de configuración
                
                menu=$(mostrarMenu "Configuración de copias de seguridad de archivos de configuración" \
                    "Opción" "Descripción" \
                    "1" "Configurar copias de seguridad para archivos" \
                    "2" "Configurar copias de seguridad para directorios" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  # Configuración de copias de seguridad para archivos
                        
                        cd /etc
                        archivos=$(seleccionarArchivo)
                        cd ->/dev/null
                        # Iteramos sobre los archivos seleccionados
                        for archivo in $archivos; do
                            # Verificamos si el archivo tiene una configuración previa.
                            cat $configEtc|grep $archivo:>/dev/null
                            if [ $? -eq 0 ]; then
                                mensaje=$(echo "El archivo $archivo ya tiene una configuración previa")
                                mostrarMensaje "$mensaje"
                            else
                                mostrarMensaje "Introduzca la configuración de copias de seguridad para el archivo $archivo"
                                configuracion=$(configurarCopiasSeguridad)
                                if [ $? -eq 0 ]; then
                                    verificarDirectorioConfiguracion
                                    # Guardamos la configuración en $configEtc. Estructura; archivo:numCopias:numDias
                                    echo "$archivo:$configuracion" >> $configEtc
                                fi
                            fi
                        done
                    ;;
                    2)  # Configuración de copias de seguridad para directorios
                        
                        cd /etc
                        directorios=$(seleccionarDirectorio)
                        cd ->/dev/null
                        # Iteramos sobre los directorios seleccionados
                        for directorio in $directorios; do
                            # Verificamos si el directorio tiene una configuración previa.
                            cat $configEtc|grep $directorio:>/dev/null
                            if [ $? -eq 0 ]; then
                                mensaje=$(echo "El directorio $directorio ya tiene una configuración previa")
                                mostrarMensaje "$mensaje"
                            else
                                mensaje=$(echo "Introduzca la configuración de copias de seguridad para el directorio $directorio")
                                mostrarMensaje "$mensaje"
                                configuracion=$(configurarCopiasSeguridad)
                                if [ $? -eq 0 ]; then
                                    verificarDirectorioConfiguracion
                                    # Guardamos la configuración en $configEtc. Estructura; directorio:numCopias:numDias
                                    echo "$directorio:$configuracion" >> $configEtc
                                fi
                            fi
                        done
                    ;;
                    3)  # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;
            3)  # Acceder a la configuración de copias de seguridad
                
                menu=$(mostrarMenu "Acceder a la configuración de copias de seguridad" \
                    "Opción" "Descripción" \
                    "1" "Acceder a la configuración de directorios de trabajo" \
                    "2" "Acceder a la configuración de archivos de configuración" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  # Acceder a la configuración de directorios de trabajo

                        menu=$(mostrarMenu "Acceder a la configuración de directorios de trabajo" \
                            "Opción" "Descripción" \
                            "1" "Modificar configuración existente para usuarios" \
                            "2" "Modificar configuración existente para grupos" \
                            "3" "Eliminar configuración existente para usuarios" \
                            "4" "Eliminar configuración existente para grupos" \
                            "5" "Salir")

                        if [ $? -eq 0 ]; then
                            case $menu in
                            1) # Modificar configuración existente para usuarios

                                configuraciones=$(mostrarConfiguracionUsuario)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    modificarConfiguracionHomeUsuario $configuracion
                                done
                            ;;
                            2) # Modificar configuración existente para grupos

                                configuraciones=$(mostrarConfiguracionGrupo)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    modificarConfiguracionHomeGrupo $configuracion
                                done
                            ;;
                            3) # Eliminar configuración existente para usuarios

                                configuraciones=$(mostrarConfiguracionUsuario)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    eliminarConfiguracionHomeUsuario $configuracion
                                done
                            ;;
                            4) # Eliminar configuración existente para grupos

                                configuraciones=$(mostrarConfiguracionGrupo)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    eliminarConfiguracionHomeGrupo $configuracion
                                done
                            ;;
                            5) # Salir

                                salida=1
                            ;;
                            esac
                        fi    
                    ;;
                    2)  # Acceder a la configuración de archivos de configuración
                        
                        menu=$(mostrarMenu "Acceder a la configuración de archivos de configuración" \
                            "Opción" "Descripción" \
                            "1" "Modificar configuración existente" \
                            "2" "Eliminar configuración existente" \
                            "3" "Salir")

                        if [ $? -eq 0 ]; then
                            case $menu in
                            1) # Modificar configuración existente

                                configuraciones=$(mostrarConfiguracionEtc)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    modificarConfiguracionEtc $configuracion
                                done
                            ;;
                            2) # Eliminar configuración existente

                                configuraciones=$(mostrarConfiguracionEtc)
                                # Iteramos sobre las configuraciones seleccionadas
                                for configuracion in $configuraciones; do
                                    eliminarConfiguracionEtc $configuracion
                                done                                
                            ;;
                            3) # Salir

                                salida=1
                            ;;
                            esac
                        fi
                                 
                    ;;
                    3)  # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;
            4)  # Restaurar copias de seguridad
                
                menu=$(mostrarMenu "Restaurar copias de seguridad" \
                    "Opción" "Descripción" \
                    "1" "Restaurar copias de seguridad de directorios de trabajo" \
                    "2" "Restaurar copias de seguridad de archivos de configuración" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1)  # Restaurar copias de seguridad de directorios de trabajo
                        
                        menu=$(mostrarMenu "Restaurar copias de seguridad de directorios de trabajo" \
                            "Opción" "Descripción" \
                            "1" "Restaurar copias de usuarios" \
                            "2" "Restaurar copias de grupos" \
                            "3" "Salir")

                        if [ $? -eq 0 ]; then
                            case $menu in
                            1)  # Restaurar copias de usuarios
                                
                                menu=$(mostrarMenu "Restaurar copias de un usuario" \
                                    "Opción" "Descripción" \
                                    "1" "Restaurar en el directorio original" \
                                    "2" "Restaurar en un directorio específico" \
                                    "3" "Salir")

                                if [ $? -eq 0 ]; then
                                    case $menu in
                                    1)  # Restaurar en el directorio original
                                        
                                        usuarios=$(mostrarUsuariosConConfiguracion)
                                        if [ $? -eq 0 ]; then
                                            # Iteramos sobre los usuarios seleccionados
                                            for usuario in $usuarios; do
                                                # eval permite expandir el contenido de la variable $usuario antes de ejecutar el comando
                                                directorio=$(eval echo ~$usuario)
                                                copia=$(mostrarCopiasSeguridadHome $usuario)
                                                if [ $? -eq 0 ]; then    
                                                    restaurarCopiaSeguridadOriginal $copia $directorio
                                                fi
                                            done
                                        fi
                                    ;;
                                    2)  # Restaurar en un directorio específico
                                        
                                        usuarios=$(mostrarUsuariosConConfiguracion)
                                        if [ $? -eq 0 ]; then
                                            # Iteramos sobre los usuarios seleccionados                                 
                                            for usuario in $usuarios; do
                                                if [ $? -eq 0 ]; then
                                                    directorio=$(introducirDirectorioRestauracion)
                                                    copia=$(mostrarCopiasSeguridadHome $usuario)
                                                    if [ $? -eq 0 ]; then    
                                                        restaurarCopiaSeguridadEspecifico $copia $directorio
                                                    fi
                                                fi
                                            done
                                        fi
                                    ;;
                                    3)  # Salir
                                        
                                        salida=1
                                    ;;
                                    esac
                                fi
                            ;;
                            2)  # Restaurar copias de grupos
                                
                                menu=$(mostrarMenu "Restaurar copias de un usuario" \
                                    "Opción" "Descripción" \
                                    "1" "Restaurar en el directorio original" \
                                    "2" "Restaurar en un directorio específico" \
                                    "3" "Salir")

                                if [ $? -eq 0 ]; then
                                    case $menu in
                                    1)  # Restaurar en el directorio original
                                        
                                        grupos=$(mostrarGruposConConfiguracion)
                                        if [ $? -eq 0 ]; then
                                            # Iteramos sobre los grupos seleccionados
                                            for grupo in $grupos; do
                                                copiaFecha=$(mostrarCopiasSeguridadHomeGrupos $grupo)
                                                if [ $? -eq 0 ]; then    
                                                    usuarios=$(extraerUsuarios $grupo)
                                                    # Iteramos sobre los usuarios de cada grupo
                                                    for usuario in $usuarios; do
                                                        directorio=$(eval echo ~$usuario)
                                                        copiaFechaInvertida=$(invertirFecha $copiaFecha)
                                                        copia=$(ls $backupHome|grep $copiaFechaInvertida|grep $usuario)
                                                        restaurarCopiaSeguridadOriginal $copia $directorio
                                                    done
                                                fi                                                
                                            done
                                        fi
                                    ;;
                                    2)  # Restaurar en un directorio específico
                                        
                                        grupos=$(mostrarGruposConConfiguracion)
                                        if [ $? -eq 0 ]; then
                                            # Iteramos sobre los grupos seleccionados
                                            for grupo in $grupos; do
                                                copiaFecha=$(mostrarCopiasSeguridadHomeGrupos $grupo)
                                                if [ $? -eq 0 ]; then
                                                    directorio=$(introducirDirectorioRestauracion)
                                                    usuarios=$(extraerUsuarios $grupo)
                                                    # Iteramos sobre los usuarios de cada grupo
                                                    for usuario in $usuarios; do
                                                        copiaFechaInvertida=$(invertirFecha $copiaFecha)
                                                        copia=$(ls $backupHome|grep $copiaFechaInvertida|grep $usuario)
                                                        restaurarCopiaSeguridadEspecifico $copia $directorio
                                                    done
                                                fi
                                            done
                                        fi
                                    ;;
                                    3)  # Salir
                                        
                                        salida=1
                                    ;;
                                    esac
                                fi
                            ;;
                            3)  # Salir
                                
                                salida=1
                            ;;
                            esac
                        fi
                    ;;
                    2)  # Restaurar copias de seguridad de archivos de configuración
                        
                        menu=$(mostrarMenu "Restaurar copias de seguridad de archivos de configuración" \
                            "Opción" "Descripción" \
                            "1" "Restaurar en el directorio original" \
                            "2" "Restaurar en un directorio específico" \
                            "3" "Salir")

                        if [ $? -eq 0 ]; then
                            case $menu in
                            1)  # Restarurar en el directorio original
                                
                                configuraciones=$(mostrarCopiasSeguridadEtc)
                                if [ $? -eq 0 ]; then
                                    # Iteramos sobre las configuraciones seleccionadas
                                    for configuracion in $configuraciones; do
                                        directorio=$(echo $configuracion|cut -d- -f4|cut -d. -f1|tr "_" "/")
                                        copia=$configuracion
                                        restaurarCopiaSeguridadEtcOriginal $copia $directorio
                                    done
                                fi
                            ;;
                            2)  # Restaurar en un directorio específico
                                
                                configuraciones=$(mostrarCopiasSeguridadEtc)
                                if [ $? -eq 0 ]; then
                                    # Iteramos sobre las configuraciones seleccionadas
                                    for configuracion in $configuraciones; do
                                        directorio=$(introducirDirectorioRestauracion)
                                        copia=$configuracion
                                        restaurarCopiaSeguridadEtcEspecifico $copia $directorio
                                    done
                                fi
                            ;;
                            3)  # Salir
                                
                                salida=1
                            ;;
                            esac
                        fi
                    ;;
                    3)  # Salir
                        
                        salida=1
                    ;;
                    esac
                fi
            ;;
            5) # Borrar copias de seguridad

                menu=$(mostrarMenu "Borrar copias de seguridad" \
                    "Opción" "Descripción" \
                    "1" "Borrar copias de seguridad de directorios de trabajo" \
                    "2" "Borrar copias de seguridad de archivos de configuración" \
                    "3" "Salir")

                if [ $? -eq 0 ]; then
                    case $menu in
                    1) # Borrar copias de seguridad de directorios de trabajo"

                        menu=$(mostrarMenu "Borrar copias de seguridad de directorios de trabajo" \
                            "Opción" "Descripción" \
                            "1" "Borrar copias de seguridad de usuarios" \
                            "2" "Borrar copias de seguridad de grupos" \
                            "3" "Salir")

                        if [ $? -eq 0 ]; then
                            case $menu in
                            1) # Borrar copias de seguridad de usuarios

                                usuarios=$(mostrarUsuariosConConfiguracion)
                                if [ $? -eq 0 ]; then
                                    # Iteramos sobre los usuarios seleccionados
                                    for usuario in $usuarios; do
                                        copia=$(mostrarCopiasSeguridadHome $usuario)
                                        if [ $? -eq 0 ]; then
                                            eliminarConfiguracionHomeUsuario $usuario                                            
                                            pregunta=$(echo "¿Desea borrar la copia de seguridad $copia?")
                                            preguntar "$pregunta"
                                            if [ $? -eq 0 ]; then
                                                sudo rm $backupHome/$copia
                                            fi
                                        fi
                                    done
                                fi
                            ;;
                            2) # Borrar copias de seguridad de grupos

                                grupos=$(mostrarGruposConConfiguracion)
                                if [ $? -eq 0 ]; then
                                    # Iteramos sobre los grupos seleccionados
                                    for grupo in $grupos; do
                                        copiaFecha=$(mostrarCopiasSeguridadHomeGrupos $grupo)
                                        if [ $? -eq 0 ]; then
                                            eliminarConfiguracionHomeGrupo $grupo
                                            pregunta=$(echo "¿Desea borrar las copias del grupo $grupo con fecha $copiaFecha?")
                                            preguntar "$pregunta"
                                            if [ $? -eq 0 ]; then
                                                usuarios=$(extraerUsuarios $grupo)
                                                # Iteramos sobre los usuarios de cada grupo
                                                for usuario in $usuarios; do
                                                    copiaFechaInvertida=$(invertirFecha $copiaFecha)
                                                    copia=$(ls $backupHome|grep $copiaFechaInvertida|grep $usuario)
                                                    echo "copia: $copia"
                                                    if [ $? -eq 0 ]; then
                                                        sudo rm $backupHome/$copia
                                                    fi
                                                done
                                            fi
                                        fi
                                    done
                                fi
                            ;;
                            3) # Salir

                                salida=1
                            ;;
                            esac
                        fi
                    ;;
                    2) # Borrar copias de seguridad de archivos de configuración

                        copias=$(mostrarCopiasSeguridadEtc)
                        if [ $? -eq 0 ]; then
                            # Iteramos sobre las copias seleccionadas
                            for copia in $copias; do
                                eliminarConfiguracionEtc $copia
                                pregunta=$(echo "¿Desea borrar la copia de seguridad $copia?")
                                preguntar "$pregunta"
                                if [ $? -eq 0 ]; then
                                    sudo rm $backupEtc/$copia
                                fi
                            done
                        fi
                    ;;
                    3) # Salir

                        salida=1
                    ;;
                    esac
                fi
            ;;
            6) # Aplicación para usuarios

                salida=1
                backupUser.sh
            ;;
            7) # Salir

                salida=1
            ;;
            esac
        else
            salida=1
        fi
    else 
        error=$(echo "No tiene permisos para ejecutar la aplicación")
        mostrarError "$error"
    fi
done
