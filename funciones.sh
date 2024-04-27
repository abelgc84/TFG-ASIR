#! /bin/bash

#############################################################################################################
# 
# Funciones utilizadas por los scripts de copias de seguridad.
# 
#############################################################################################################

#################################################
# mostrarMenu
# Muestra un menú con Zenity con dos columnas
# Parámetros:
#   $1: Título del menú
#   $2: Título de la primera columna
#   $3: Título de la segunda columna
#   $@: Elementos del menú, impares son la primera columna y pares la segunda
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
# Salida:
#   Lista de usuarios seleccionados separados por espacios
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
# Salida:
#   Lista de grupos seleccionados separados por espacios
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
#   Directorio seleccionado
#################################################
seleccionarDirectorio () {
    zenity --title="Selecciona un directorio" \
        --file-selection \
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
#   Lista de usuarios de los grupos separados por espacios
#################################################
extraerUsuarios () {
    grupos=$@
    usuarios=""
    for grupo in $grupos; do
        # Extraemos los usuarios de cada grupo, -v grupo=$grupo para pasar el valor de la variable grupo a awk
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
                echo "$numCopias:$numDias"
                salidaConfig=1
            fi
        else
            salidaConfig=1
        fi
    done
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
# verificarDirectorioUsuario
# Verifica si existe el directorio /backup/$USER y si no lo crea
#################################################
verificarDirectorioUsuario () {
    if [ ! -d /backup/$USER ]; then
        mkdir -p /backup/$USER
    fi
}

#################################################
# mostrarConfiguracionUsuario
# Muestra con Zenity la configuración de copias de seguridad existente de los usuarios
# Salida:
#   Lista de usuarios seleccionados separados por espacios
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
# Salida:
#   Lista de grupos seleccionados separados por espacios
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
# Salida:
#   Lista de archivos seleccionados separados por espacios
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
        # sed 's/[^-A-Za-z0-9_]/\\&/g') - Indica que se reemplazan todos los caracteres que no sean letras, números o guiones por el mismo caracter escapado (\)
        configuracionEscapada=$(echo $configuracion | sed 's/[^-A-Za-z0-9_]/\\&/g')
        sed -i "/$configuracionEscapada/d" $configEtc
    fi
}

#################################################
# mostrarUsuariosConConfiguracion
# Muestra los usuarios que tienen una configuración de copias de seguridad
# Salida:
#   Lista de usuarios seleccionados separados por espacios
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
# Salida:
#   Lista de grupos seleccionados separados por espacios
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
#  $1: Usuario
# Salida:
#  Copia de seguridad seleccionada
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
# Restaura una copia de seguridad de un directorio home en el directorio original
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadOriginal () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupHome/$copia -C /
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f2)
    sudo chown -R $usuario:$grupo $directorio
}

#################################################
# restaurarCopiaSeguridadEspecifico
# Restaura una copia de seguridad de un directorio home en un directorio específico
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadEspecifico () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupHome/$copia -C $directorio
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f2)
    sudo chown -R $usuario:$grupo $directorio
}

#################################################
# mostrarCopiasSeguridadEtc
# Muestra las copias de seguridad de archivos de configuración existentes con Zenity
# Salida:
#  Copias de seguridad seleccionadas separadas por espacios
#################################################
mostrarCopiasSeguridadEtc () {
    zenity --list \
        --title="Copias de seguridad de archivos de configuración" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Copia de seguridad" \
        $(ls -1 $backupEtc)
}

#################################################
# restaurarCopiaSeguridadEtcOriginal
# Restaura una copia de seguridad de un archivo de configuración
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadEtcOriginal () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupEtc/$copia -C /
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f3)
    sudo chown -R $usuario:$grupo $directorio
}

#################################################
# restaurarCopiaSeguridadEtcEspecifico
# Restaura una copia de seguridad de un archivo de configuración en un directorio específico
# Parámetros:
#  $1: Copia de seguridad
#  $2: Directorio de restauración
#################################################
restaurarCopiaSeguridadEtcEspecifico () {
    copia=$1
    directorio=$2
    sudo tar -xzf $backupEtc/$copia -C $directorio
    usuario=$(echo $copia | cut -d- -f2)
    grupo=$(echo $copia | cut -d- -f3)
    sudo chown -R $usuario:$grupo $directorio
}

#################################################
# copiaSeguridadCompleta
# Realiza una copia de seguridad completa de archivos o directorios
# Parámetros:
#  $@: Archivos o directorios a copiar
#################################################
copiaSeguridadCompleta () {
    if [ ! -d $backupDestino ]; then
        mkdir -p $backupDestino
    fi
    for fichero in $@; do
        echo "Fichero: $fichero"
        shift
        copia=$(extraerNombre $fichero)
        tar -czf $backupDestino/$fechaActual-$copia.tar.gz $fichero
        echo "Copia:$fechaActual:$USER:$copia.tar.gz" >> /backup/config/backups-completos.log
    done
}

#################################################
# anadirDirectorioEspejo
# Añade un directorio espejo a la configuración
# Parámetros:
#  $1: Directorio a añadir
#################################################
anadirDirectorioEspejo () {
    if [ ! -d $directorio ]; then
        error=$(echo -e "El directorio $directorio no existe.\nDebe seleccionar un directorio válido.")
        mostrarError "$error"
    else
        verificarDirectorioUsuario
        configuracion="$USER:$directorio"
        if [ ! -z $directorio ]; then
            echo $configuracion >> $configEspejo
        fi
    fi
}

#################################################
# eliminarDirectorioEspejo
# Elimina un directorio espejo de la configuración
# Parámetros:
#  $1: Directorio a eliminar
#################################################
eliminarDirectorioEspejo () {
    if [ ! -d $directorio ]; then
        error=$(echo -e "El directorio $directorio no existe.\nDebe seleccionar un directorio válido.")
        mostrarError "$error"
    else
        pregunta=$(echo "¿Desea eliminar el directorio espejo $directorio?")
        preguntar "$pregunta"
        if [ $? -eq 0 ]; then
            directorioEscapado=$(echo $directorio | sed 's/[^-A-Za-z0-9_]/\\&/g')
            sed -i "/$directorioEscapado/d" $configEspejo
            directorioBackup=$(echo $directorio | sed 's/home/backup/')
            if [ -d $directorioBackup ]; then
                sudo rm -r $directorioBackup
            fi
        fi
    fi
}

#################################################
# mostrarDirectoriosEspejo
# Muestra los directorios espejo con Zenity
# Salida:
#  Directorios espejo seleccionados separados por espacios
#################################################
mostrarDirectoriosEspejo () {
    zenity --list \
        --title="Directorios espejo" \
        --width="600" \
        --height="500" \
        --multiple \
        --separator=" " \
        --column="Directorio" \
        $(awk -F: '{print $2}' $configEspejo)
}

#################################################
# mostrarCopiasSeguridadCompleta
# Muestra las copias de seguridad completas existentes con Zenity
# Salida:
#  Copia de seguridad seleccionada
#################################################
mostrarCopiasSeguridadCompleta () {
    zenity --list \
        --title="Copias de seguridad completas" \
        --width="600" \
        --height="500" \
        --column="Copia de seguridad" \
        $(ls -1 $backupDestino|grep .tar.gz)
}

#################################################
# restaurarCopiaSeguridadCompleta
# Restaura una copia de seguridad completa
# Parámetros:
#  $1: Copia de seguridad
#################################################
restaurarCopiaSeguridadCompleta () {
    tar -xzf $backupDestino/$1 -C /
    echo "Restaurar:$USER:$backupDestino/$1" >> /backup/config/backups-completos.log
}