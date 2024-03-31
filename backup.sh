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
fechaActual=$(date +"%Y%m%d")
backupDestino="/backup/$USER"
backupHome="/backup/home"
backupEtc="/backup/etc"
configHome="/backup/config/backups-home.conf"
configEtc="/backup/config/backups-etc.conf"



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
# mostrarUsuarios
# Muestra la lista de usuarios con Zenity
# Muestra los usuarios con UID entre 1000 y 65000
#################################################
mostrarUsuarios () {
    zenity --list \
        --title="Selecciona un usuario" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Usuario" \
        $(awk -F: '$3 >= 1000 && $3 <= 65000 {print $1}' /etc/passwd)
}

#################################################
# mostrarGrupos
# Muestra la lista de grupos con Zenity
# Muestra los grupos con GID entre 1000 y 65000 y que tengan usuarios
#################################################
mostrarGrupos () {
    zenity --list \
        --title="Selecciona un grupo" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Grupo" \
        $(awk -F: '$3 >= 1000 && $3 <= 65000 && $4 != "" {print $1}' /etc/group)
}

#################################################
# seleccionarArchivo
# Muestra una ventana de selección de archivos con Zenity
# Salida:
#   Lista de archivos seleccionados
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
#   Lista de directorios seleccionados
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
# invertirFecha
# Invierte la fecha entre los formatos AAAAMMDD y DD/MM/YYYY
# Parámetros:
#   $1: Fecha en un formato u otro
# Salida:
#   Fecha invertida
#################################################
invertirFecha () {
    fecha=$1
    if [[ $fecha =~ ^[0-9]{8}$ ]]; then
        echo ${fecha:6:2}/${fecha:4:2}/${fecha:0:4}
    else
        echo ${fecha:6:4}${fecha:3:2}${fecha:0:2}
    fi
}

#################################################
# extraerUsuarios
# Extrae los usuarios de una lista de grupos
# Parámetros:
#   $@: Lista de grupos
# Salida:
#   Lista de usuarios de los grupos
#################################################
extraerUsuarios () {
    grupos=$@
    usuarios=""
    for grupo in $grupos; do
        # Extraemos los usuarios de cada grupo
        usuarios="$usuarios $(awk -F: -v grupo=$grupo '$1 == grupo {print $4}' /etc/group)"
    done
    # Sustituimos las comas por espacios
    usuarios=$(echo $usuarios | tr ',' ' ')
    echo $usuarios
}

#################################################
# configurarCopiasSeguridad
# Solicita el número de copias de seguridad a mantener y el número de días entre copias de seguridad con Zenity
# Salida:
#   numCopias:numDias Número de copias a mantener y número de días entre copias de seguridad
#################################################
configurarCopiasSeguridad () {
    salidaConfig=0
    while [ $salidaConfig -eq 0 ]; do

        configuracion=$(zenity --forms \
            --title="Configuración de copias de seguridad" \
            --text="Introduce los datos para la configuración de copias de seguridad" \
            --width="600" \
            --separator=":" \
            --add-entry="Número de copias a mantener" \
            --add-entry="Número de días entre copias de seguridad")
        
        if [ $? -eq 0 ]; then 

            numCopias=$(echo $configuracion | cut -d: -f1)
            numDias=$(echo $configuracion | cut -d: -f2)
        
            # Verificamos que numCopias y numDias sean números enteros positivos
            # Se compara con la expresión regular (=~) ^[0-9]+$ que indica que la cadena comienza (^) y termina ($) con un número
            if ! [[ $numCopias =~ ^[0-9]+$ ]] || ! [[ $numDias =~ ^[0-9]+$ ]]; then
                error=$(echo -e "Los valores introducidos no son correctos.\nDebe introducir números enteros positivos.")
                mostrarError "$error"
            else
                salidaConfig=1
            fi

        else
            salidaConfig=1
        fi
    
    done

    if [ -n $configuracion ]; then
        echo $configuracion
    fi
}

#################################################
# verificarDirectorioConfiguracion
# Verifica si existe el directorio /backup/config y si no lo crea
#################################################
verificarDirectorioConfiguracion () {
    if [ ! -d /backup/config ]; then
        mkdir -p /backup/config
    fi
}

#################################################
# copiaSeguridadCompleta
# Realiza una copia de seguridad completa de los archivos o directorios seleccionados
# Parámetros:
#   $1: Tipo de copia de seguridad (archivos o directorios)
#################################################
copiaSeguridadCompleta () {
    
    # Comprobamos si existe el directorio de destino
    if [ ! -d $backupDestino ]; then
        mkdir -p $backupDestino
    fi

    # Seleccionamos los archivos a copiar
    case $1 in
    archivos)
        ficheros=$(seleccionarArchivo)
    ;;
    directorio)
        ficheros=$(seleccionarDirectorio)
    ;;
    esac
    
    # Copiamos los archivos - fecha-usuario-grupo-nombre.tar.gz
    for fichero in $ficheros; do
        usuario=$(stat -c "%U" $fichero)
        grupo=$(stat -c "%G" $fichero)
        nombre=$(extraerNombre $fichero)
        destino="$backupDestino/$fechaActual-$usuario-$grupo-$nombre"
        tar -czf "$destino".tar.gz $fichero
    done
}

#################################################
# mostrarConfiguracionUsuario
# Muestra con Zenity la configuración de copias de seguridad existente de los usuarios
#################################################
mostrarConfiguracionUsuario () {
    zenity --list \
        --title="Configuración de copias de seguridad" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Usuario" \
        --column="Grupo" \
        --column="Número de copias" \
        --column="Número de días" \
        $(awk -F: '$1==$2 {print $1, $2, $3, $4}' $configHome)
}

#################################################
# mostrarConfiguracionGrupo
# Muestra con Zenity los grupos que tengan una configuración existente
#################################################
mostrarConfiguracionGrupo () {
    zenity --list \
        --title="Configuración de copias de seguridad" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Grupo" \
        --column="Número de copias" \
        --column="Número de días" \
        $(awk -F: '$1!=$2 {print $2, $3, $4}' $configHome|sort -u)
}

#################################################
# mostrarConfiguracionEtc
# Muestra con Zenity la configuración de copias de seguridad existente de los archivos de configuración
#################################################
mostrarConfiguracionEtc () {
    zenity --list \
        --title="Configuración de copias de seguridad" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Archivo" \
        --column="Número de copias" \
        --column="Número de días" \
        $(awk -F: '{print $1, $2, $3}' $configEtc)
}

#################################################
# modificarConfiguracionHomeUsuario
# Modifica la configuración de copias de seguridad en el archivo de configuración para los usuarios seleccionados
# Parámetros:
#  $1: Usuarios a modificar
#################################################
modificarConfiguracionHomeUsuario () {
    configuracion=$(cat $configHome|grep $1:)
    usuario=$(echo $configuracion | cut -d: -f1)
    grupo=$(echo $configuracion | cut -d: -f2)
    mensaje=$(echo "Introduzca la configuración de copias de seguridad para el usuario $usuario")
    mostrarMensaje "$mensaje"
    salidaConfig=0
    while [ $salidaConfig -eq 0 ]; do
        nuevaConfiguracion=$(zenity --forms \
            --title="Modificar configuración de copias de seguridad" \
            --text="Introduce los nuevos datos para la configuración de copias de seguridad" \
            --width="600" \
            --separator=":" \
            --add-entry="Número de copias a mantener" \
            --add-entry="Número de días entre copias de seguridad")
        
        if [ $? -eq 0 ]; then 

            numCopias=$(echo $nuevaConfiguracion | cut -d: -f1)
            numDias=$(echo $nuevaConfiguracion | cut -d: -f2)
        
            # Verificamos que numCopias y numDias sean números enteros positivos
            # Se compara con la expresión regular (=~) ^[0-9]+$ que indica que la cadena comienza (^) y termina ($) con un número
            if ! [[ $numCopias =~ ^[0-9]+$ ]] || ! [[ $numDias =~ ^[0-9]+$ ]]; then
                error=$(echo -e "Los valores introducidos no son correctos.\nDebe introducir números enteros positivos.")
                mostrarError "$error"
            else
                nuevaConfiguracion="$usuario:$grupo:$nuevaConfiguracion"
                # Modificamos la configuración en el archivo de configuración
                sed -i "s/$configuracion/$nuevaConfiguracion/" $configHome
                salidaConfig=1
            fi
        else
            salidaConfig=1
        fi
    done    
}

#################################################
# modificarConfiguracionHomeGrupo
# Modifica la configuración de copias de seguridad en el archivo de configuración para todos los usuarios de los grupos seleccionados
# Parámetros:
#  $1: Grupos a modificar
#################################################
modificarConfiguracionHomeGrupo () {
    configuracion=$(cat $configHome|cut -d: -f2-4|grep $1:|sort -u)
    grupo=$(echo $configuracion | cut -d: -f1)
    mensaje=$(echo "Introduzca la configuración de copias de seguridad para el grupo $grupo")
    mostrarMensaje "$mensaje"
    salidaConfig=0
    while [ $salidaConfig -eq 0 ]; do
        nuevaConfiguracion=$(zenity --forms \
            --title="Modificar configuración de copias de seguridad" \
            --text="Introduce los nuevos datos para la configuración de copias de seguridad" \
            --width="600" \
            --separator=":" \
            --add-entry="Número de copias a mantener" \
            --add-entry="Número de días entre copias de seguridad")
        
        if [ $? -eq 0 ]; then 

            numCopias=$(echo $nuevaConfiguracion | cut -d: -f1)
            numDias=$(echo $nuevaConfiguracion | cut -d: -f2)
        
            # Verificamos que numCopias y numDias sean números enteros positivos
            # Se compara con la expresión regular (=~) ^[0-9]+$ que indica que la cadena comienza (^) y termina ($) con un número
            if ! [[ $numCopias =~ ^[0-9]+$ ]] || ! [[ $numDias =~ ^[0-9]+$ ]]; then
                error=$(echo -e "Los valores introducidos no son correctos.\nDebe introducir números enteros positivos.")
                mostrarError "$error"
            else
                nuevaConfiguracion="$grupo:$nuevaConfiguracion"
                # Modificamos la configuración en el archivo de configuración
                sed -i "s/$configuracion/$nuevaConfiguracion/" $configHome
                salidaConfig=1
            fi
        else
            salidaConfig=1
        fi
    done    
}

#################################################
# eliminarConfiguracionHomeUsuario
# Elimina la configuración de copias de seguridad en el archivo de configuración para los usuarios seleccionados
# Parámetros:
#  $1: Usuarios a eliminar
#################################################
eliminarConfiguracionHomeUsuario () {
    configuracion=$(cat $configHome|grep $1:)
    echo "configuracion: $configuracion"
    # Eliminamos la configuración en el archivo de configuración
    pregunta=$(echo "¿Desea eliminar la configuración de copias de seguridad para el usuario $1?")
    preguntar "$pregunta"
    if [ $? -eq 0 ]; then
        sed -i "/$configuracion/d" $configHome
    fi
}

#################################################
# eliminarConfiguracionHomeGrupo
# Elimina la configuración de copias de seguridad en el archivo de configuración para todos los usuarios de los grupos seleccionados
# Parámetros:
#  $1: Grupos a eliminar
#################################################
eliminarConfiguracionHomeGrupo () {
    configuracion=$(cat $configHome|cut -d: -f2-4|grep $1:|sort -u)
    grupo=$(echo $configuracion | cut -d: -f1)
    # Eliminamos la configuración en el archivo de configuración
    pregunta=$(echo "¿Desea eliminar la configuración de copias de seguridad para el grupo $grupo?")
    preguntar "$pregunta"
    if [ $? -eq 0 ]; then
        sed -i "/$configuracion/d" $configHome
    fi
}

#################################################
# modificarConfiguracionEtc
# Modifica la configuración de copias de seguridad en el archivo de configuración
# Parámetros:
#  $1: Configuraciones a modificar
#################################################
modificarConfiguracionEtc () {
    configuracion=$(cat $configEtc|grep $1:)
    archivo=$(echo $configuracion | cut -d: -f1)
    mensaje=$(echo "Introduzca la configuración de copias de seguridad para el archivo $archivo")
    mostrarMensaje "$mensaje"
    salidaConfig=0
    while [ $salidaConfig -eq 0 ]; do
        nuevaConfiguracion=$(zenity --forms \
            --title="Modificar configuración de copias de seguridad" \
            --text="Introduce los nuevos datos para la configuración de copias de seguridad" \
            --width="600" \
            --separator=":" \
            --add-entry="Número de copias a mantener" \
            --add-entry="Número de días entre copias de seguridad")
        
        if [ $? -eq 0 ]; then 

            numCopias=$(echo $nuevaConfiguracion | cut -d: -f1)
            numDias=$(echo $nuevaConfiguracion | cut -d: -f2)
        
            # Verificamos que numCopias y numDias sean números enteros positivos
            # Se compara con la expresión regular (=~) ^[0-9]+$ que indica que la cadena comienza (^) y termina ($) con un número
            if ! [[ $numCopias =~ ^[0-9]+$ ]] || ! [[ $numDias =~ ^[0-9]+$ ]]; then
                error=$(echo -e "Los valores introducidos no son correctos.\nDebe introducir números enteros positivos.")
                mostrarError "$error"
            else
                nuevaConfiguracion="$archivo:$nuevaConfiguracion"
                # Modificamos la configuración en el archivo de configuración
                # El delimitador de sed es el caracter | para evitar conflictos con las barras de la ruta del archivo
                sed -i "s|$configuracion|$nuevaConfiguracion|" $configEtc
                salidaConfig=1
            fi
        else
            salidaConfig=1
        fi    
    done    
}

#################################################
# eliminarConfiguracionEtc
# Elimina la configuración de copias de seguridad en el archivo de configuración
# Parámetros:
#  $1: Configuraciones a eliminar
#################################################
eliminarConfiguracionEtc () {
    configuracion=$(cat $configEtc|grep $1:)
    archivo=$(echo $configuracion | cut -d: -f1)
    # Eliminamos la configuración en el archivo de configuración
    pregunta=$(echo "¿Desea eliminar la configuración de copias de seguridad para el archivo $archivo?")
    preguntar "$pregunta"
    if [ $? -eq 0 ]; then
        # Escapamos los caracteres especiales de la configuración para que sed no los interprete
        # sed 's/[^-A-Za-z0-9_]/\\&/g') - Indica que se reemplazan todos los caracteres que no sean letras, números o guiones bajos por el mismo caracter escapado (\)
        configuracionEscapada=$(echo $configuracion | sed 's/[^-A-Za-z0-9_]/\\&/g')
        sed -i "/$configuracionEscapada/d" $configEtc
    fi
}

#################################################
# mostrarUsuariosConConfiguracion
# Muestra los usuarios que tienen una configuración de copias de seguridad
#################################################
mostrarUsuariosConConfiguracion () {
    usuarios=$(awk -F: '$1==$2 {print $1}' $configHome)
    zenity --list \
        --title="Usuarios con configuración de copias de seguridad" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Usuario" \
        $usuarios
}

#################################################
# mostrarGruposConConfiguracion
# Muestra los grupos que tienen una configuración de copias de seguridad
#################################################
mostrarGruposConConfiguracion () {
    grupos=$(awk -F: '$1!=$2 {print $2}' $configHome|sort -u)
    zenity --list \
        --title="Grupos con configuración de copias de seguridad" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Grupo" \
        $grupos
}

#################################################
# mostrarCopiasSeguridadHome
# Muestra las copias de seguridad existentes con Zenity
# Parámetros:
#  $1: Usuario o grupo
#################################################
mostrarCopiasSeguridadHome () {
    zenity --list \
        --title="Copias de seguridad de $1" \
        --width="600" \
        --height="500" \
        --column="Copia de seguridad" \
        $(ls -1 $backupHome|grep $1)
}

#################################################
# mostrarCopiasSeguridadHomeGrupos
# Muestra la fecha en formato DD/MM/YYYY de las copias de seguridad únicas de un grupo
# Parámetros:
#  $1: Grupo
#################################################
mostrarCopiasSeguridadHomeGrupos () {
    copias=$(ls $backupHome|grep $1|cut -d- -f1|sort -u)
    fechas=""
    for copia in $copias; do
        fecha=$(invertirFecha $copia)
        fechas="$fechas $fecha"
    done
    zenity --list \
        --title="Copias de seguridad de $1" \
        --width="600" \
        --height="500" \
        --column="Fecha" \
        $fechas
}

#################################################
# introducirDirectorioRestauracion
# Solicita el directorio de restauración con Zenity
# Salida:
#   Directorio de restauración
#################################################
introducirDirectorioRestauracion () {
    zenity --file-selection \
        --title="Selecciona un directorio para la restauración" \
        --directory
}

#################################################
# restaurarCopiaSeguridadOriginal
# Restaura una copia de seguridad en el directorio original
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadOriginal () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupHome/$copia -C /
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f3)
    sudo chown -R $usuario:$grupo $directorio
}

#################################################
# restaurarCopiaSeguridadEspecifico
# Restaura una copia de seguridad en un directorio específico
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadEspecifico () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupHome/$copia -C $directorio
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f3)
    sudo chown -R $usuario:$grupo $directorio
}

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
        # Menú para administradores
        main=$(mostrarMenu "Copia de seguridad para administración" \
            "Opción" "Descripción" \
            "1" "Configurar copias de seguridad de los directorios de trabajo" \
            "2" "Configurar copias de seguridad de archivos de configuración" \
            "3" "Acceder a la configuración de copias de seguridad" \
            "4" "Restaurar copias de seguridad" \
            "5" "Aplicación para usuarios" \
            "6" "Salir")
        if [ $? -eq 0 ]; then
            case $main in
            1)
                # Configuración de copias de seguridad de los directorios de trabajo
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
                                    verificarDirectorioConfiguracion
                                    # Guardamos la configuración en $configHome. Estructura; usuario:grupo:numCopias:numDias
                                    echo "$usuario:$usuario:$configuracion" >> $configHome
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
                                            for grupo in $grupos; do
                                                copiaFecha=$(mostrarCopiasSeguridadHomeGrupos $grupo)
                                                if [ $? -eq 0 ]; then    
                                                    usuarios=$(extraerUsuarios $grupo)
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
                                            for grupo in $grupos; do
                                                copiaFecha=$(mostrarCopiasSeguridadHomeGrupos $grupo)
                                                if [ $? -eq 0 ]; then
                                                    directorio=$(introducirDirectorioRestauracion)
                                                    usuarios=$(extraerUsuarios $grupo)
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
                            "1" "Restarurar en el directorio original" \
                            "2" "Restaurar en un directorio específico" \
                            "3" "Salir")
                        if [ $? -eq 0 ]; then
                            case $menu in
                            1)  # Restarurar en el directorio original
                                
                                echo "Restarurar en el directorio original"
                            ;;
                            2)  # Restaurar en un directorio específico
                                
                                echo "Restaurar en un directorio específico"
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
            5) # Aplicación para usuarios

                preguntar "¿Desea cambiar a la aplicación para usuarios?"
                if [ $? -eq 0 ]; then
                    permisos="usuario"
                fi
            ;;
            6) # Salir

                salida=1
            ;;
            esac
        else
            salida=1
        fi
    else 
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
    fi
done
