#!/bin/bash
reporte="Reporte.txt"
# Obtener la ruta absoluta del directorio donde está este script
DIR="$(cd "$(dirname "$0")" && pwd)"
# Ruta del archivo CSV dentro del mismo directorio
VENTAS="$DIR/ventas.csv"

# Función para mostrar los 10 productos más vendidos
declare -A Productos
function productos_mas_vendido() {
    echo "----------------------------------------------"
    echo "      TOP 10 PRODUCTOS MÁS VENDIDOS:" | tee -a "$reporte" 
    echo "----------------------------------------------"
    while IFS=";" read -r producto cantidad; do
        # verificar que la cantidad sea un número
        if [[ $cantidad =~ ^[0-9]+$ ]]; then
            # Sumar la cantidad al producto existente o inicializarlo
            Productos["$producto"]=$(( ${Productos["$producto"]} + cantidad ))
        fi
    done < <(cut -d';' -f 1,6 "$VENTAS")

     #Ordenar y mostrar los 10 productos más vendidos
    for producto in "${!Productos[@]}"; do
        
        echo "${Productos[$producto]} $producto"
    done | sort -nr | head -n 10 | tee -a "$reporte" 
}

# Función para ingresos por categoría
declare -A Categorias
function ingresos_por_categoria() {
    echo "----------------------------------------------"
    echo "      TOTAL DE INGRESOS POR CATEGORÍA:" | tee -a "$reporte"
    echo "----------------------------------------------"
    {
    read  # Saltar la primera línea (cabecera)
    while IFS=";" read -r producto categoria cliente depto fecha cantidad precio ingreso; do
        if [[ -n "$categoria" && -n "$ingreso" ]]; then
            Categorias["$categoria"]=$(awk "BEGIN {print ${Categorias["$categoria"]:-0} + $ingreso}")
        fi
    done
    } < "$VENTAS"

    for categoria in "${!Categorias[@]}"; do
        printf "%s: %.2f\n" "$categoria" "${Categorias[$categoria]}"
    done | sort | tee -a "$reporte"
}

# Función para ingresos por mes (corregida para formato DD/MM/YYYY)
declare -A Meses
function ingresos_por_mes() {
    echo "----------------------------------------------"
    echo "      TOTAL DE INGRESOS POR MES:" | tee -a "$reporte"
    echo "----------------------------------------------"
    {
    read  # Saltar cabecera
    while IFS=";" read -r producto categoria cliente depto fecha cantidad precio ingreso; do
        if [[ -n "$fecha" && -n "$ingreso" ]]; then
            # Convertir fecha DD/MM/YYYY a formato YYYY-MM
            IFS='/' read -ra FECHA <<< "$fecha"
            mes=$(printf "%04d-%02d" "${FECHA[2]}" "${FECHA[1]}")
            
            if [[ -n "$mes" ]]; then
                Meses["$mes"]=$(awk "BEGIN {print ${Meses["$mes"]:-0} + $ingreso}")
            fi
        fi
    done
    } < "$VENTAS"

    for mes in "${!Meses[@]}"; do
        printf "%s: %.2f\n" "$mes" "${Meses[$mes]}"
    done | sort | tee -a "$reporte"
}

# Función para mostrar la lista de ingresos por clientes
declare -A Clientes
function ingresos_por_clientes() {
    echo "----------------------------------------------"
    echo "      TOTAL DE INGRESOS POR CLIENTES:" | tee -a "$reporte"
    echo "----------------------------------------------"
    # Leer el archivo y llenar el arreglo
   while IFS=";" read -r cliente ingreso; do
        valor_actual=${Clientes["$cliente"]} #Guarda el ingreso actual del cliente desde el array
        if [[ -z "$valor_actual" ]]; then #verificar si la variable valor_actual está vacía
            valor_actual=0
        fi
        nuevo_total=$(awk "BEGIN {print $valor_actual + $ingreso}")
        Clientes["$cliente"]=$nuevo_total # Guardar el nuevo total en el array Clientes
    
    done < <(cut -d';' -f 3,8 "$VENTAS") ## Tomar solo la columna 3 y 8


    # Mostrar ingresos por cliente ordenados alfabéticamente
    for cliente in "${!Clientes[@]}"; do # recorrer el arreglo Clientes
        printf "%s: %.2f\n" "$cliente" "${Clientes[$cliente]}"
    done | sort | tee -a "$reporte"  #Mostar los nombres de los clientes por orden alfabético
}

# Función para mostrar los ingresos por departamentos
declare -A Departamentos
function ingresos_por_departamentos(){
    {
    read 
    while IFS=";" read -r producto categoria cliente depto fecha cantidad precio ingreso; do
        if [[ -n "$depto" && -n "$ingreso" ]]; then
            #Suma
            Departamentos["$depto"]=$(awk "BEGIN {print ${Departamentos["$depto"]:-0} + $ingreso}")
        fi
        done
    } < "$VENTAS"

#reporte
echo "----------------------------------------------"
echo "      REPORTE DE INGRESOS POR DEPARTAMENTO"    | tee -a "$reporte"
echo "----------------------------------------------"
for depto in "${!Departamentos[@]}"; do
    printf "%s: %.2f\n" "$depto" "${Departamentos[$depto]}"
done | LC_ALL=C sort | tee -a "$reporte"
}


productos_mas_vendido
ingresos_por_categoria
ingresos_por_mes
ingresos_por_clientes
ingresos_por_departamentos

