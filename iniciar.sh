#!/bin/bash
#variables
front=1
api=1
gemelo=1
git=0
nopushear=1
plc=1
nombreFront="frontend"
repositorio=$1




#COLORES
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
AZUL='\033[0;34m'
NC='\033[0m' 
AZUL_FLOJO='\033[0;36m'

if !net session > /dev/null 2>&1; then
    echo -e "${AMARILLO} Si${NC} es la primera vez que ejecutas este script ejecutalo en una terminal como ${AZUL_FLOJO}ADMINISTRADOR${NC}"
fi

progreso (){
(for i in {1..100}; do
      echo $i
          sleep 0.1
        done
        ) | zenity --progress --title="Progreso" --text="Cargando..." --percentage=0 --auto-close&


}
seleccionarProyectos (){
  SELECCION=""
  while [[ -z "$SELECCION" ]]; do
  SELECCION=$(zenity --list --title="Selecciona una o más opciones" --multiple  --modal --column="Opciones" "API ⚙" "Frontend 📺" "Gemelo Digital 👭")
  if [[ $? -eq 1 ]]; then
    echo "Operación cancelada"
    exit -1
  fi
  if [[ $(echo $SELECCION | grep Gemelo | wc -l) -eq 1 && ($(echo $SELECCION | grep API | wc -l) -eq 1 || $(echo $SELECCION | grep Frontend | wc -l) -eq 1) ]]; then
    SELECCION=""
    zenity --warning --text "No puedes selecionar gemelo y los demas al mismo tiempo"
  fi
  done
  echo -e "Opción seleccionada: ${AMARILLO}$SELECCION${NC}"
 }

if [[ $(ls -a | grep .git | wc -l) -eq 1 ]]; then
    git=0
    nopushear=1
else
    git=1
    nopushear=0
fi

if [[ -z $repositorio ]]; then
    nopushear=1
    git=0
fi
gemelo() {

for ((i = 0; i < ${#carpetasGemelos[@]}; i++)); do
    cp -r ${carpetasGemelos[i]} . 
done

  #Estructura
    # - componentes
    # - vdb
  declare -a versiones
  for version in $(cat database.opt);
  do
    versiones+=("$version")
  done
  rm database.opt &
  influxdbVersion=""
while [[ -z "$influxdbVersion" ]]; do
influxdbVersion=$(zenity --list -no-cancel --title="Versión de influxdb" --text "Selecciona la versión de influxdb a utilizar" --modal --column="Opciones" "${versiones[@]}")  
 if [[ $? -eq 1 ]]; then
    zenity --warning --text "debes elegir alguna"
  fi
done
influxdbVersion="$(echo $influxdbVersion | awk -F "_" '{print $2}')"

  declare -a componentes
  for componente in $(cat visualizacion.opt);
  do
    componentes+=("$componente")
  done
  rm visualizacion.opt &

  #componetes de visualización
seleccionRealizada=0

while [[ $seleccionRealizada -eq 0 ]]; do
  visualizacion=$(zenity --list --title="Selecciona los componentes de visualización" --multiple --modal --column="Opciones" "${componentes[@]}")  
  if [[ $? -eq 1 || -z visualizacion ]]; then
    zenity --warning --text "debes elegir alguna"
    visualizacion=""
  fi

  if [[ $(echo $visualizacion | grep Influx| wc -l) -eq 1 ]]; then
      zenity --warning --title "Opción en desarrollo" --text "Opcion en desarrollo no utilizar Influxdb v2 para visualización"
    else
      if [[ ! -z $visualizacion ]];then
      seleccionRealizada=1
      fi
  fi
done

#preparar para hacer frontend
if [[ $(echo $visualizacion | grep Frontend | wc -l) -eq 1 ]]; then
  SELECCION=$(echo "${SELECCION}Frontend")
  nombreGrafana=1
fi

if [[ $(echo $visualizacion | grep Grafana | wc -l) -eq 1 ]]; then
        cat "grafana-compose.yaml" >> docker-compose.yaml &
else
  rm -rf grafana &
fi
rm -rf grafana-compose.yaml &


  #fuentes de datos telegraf
  mapfile -t inputs < <(find /proyectos/gemelo/telegraf/inputs/ | while read line; do echo $(basename $line);done | awk -F "." 'NR>1{print $1}')

  inputs=$(zenity --list --title="Selecciona los componentes de visualización" --multiple --modal --column="Opciones" "${inputs[@]}")  
  telegraf="telegraf/telegraf.conf"
  mv telegraf/base.conf $telegraf &
  http=$(cuantosInputs "http")
  mqtt=$(cuantosInputs "mqtt")
  plc=$(cuantosInputs "plc")

  if [[ $(echo $inputs | grep "plc" | wc -l) -eq 1 ]]; then
    plc=1
  else
    plc=0
  fi
  

  echo "http $http mqtt $mqtt plc $plc"
  #procesar inputs
#http
if [[ $http -gt 0 ]];then
zenity --question --text "Sabes alguna fuente de datos para HTTP"
if [[ $? -eq 1 ]];then
  meterVacio "http" $http
else
  meterHTTP $http
fi
fi 
#mqtt
if [[ $mqtt -gt 0 ]];then
zenity --question --text "Sabes alguna fuente de datos para MQTT"
if [[ $? -eq 1 ]];then
  meterVacio "mqtt" $mqtt
else
  meterMQTT $mqtt
fi
fi 

if [[ $plc -gt 0 ]];then
meterPLC $plc &
fi

if [[ $plc -eq 0 ]]; then
  rm ./telegraf/Dockerfile-python &
fi

sed "s/SUPER/$(basename $(pwd))/g" -i docker-compose.yaml
sed "s/VERSION/$influxdbVersion/g" -i docker-compose.yaml

rm -rf ./telegraf/inputs/ ./telegraf/outputs/ &
   

}
elegirMetodoHttp() {
  metodo=$(zenity --list --modal --text "Elige el metodo HTTP" --column "Metodos" "GET" "POST" "PUT" "DELETE" "HEAD" "OPTIONS" "NO SE")
  if [[ $? -eq 1 ]];then
    metodo="NO SE"
  fi
  echo $metodo


}
obtenerDato() {

    valor=$(zenity --entry --title "$2" --text "$1" --no-cancel --modal --entry-text "$3")
    estado=$?
    echo $valor
    return $estado
}
meterHTTP(){
  cantidad=$1
  ruta="telegraf/inputs/http.conf"
  copia="telegraf/inputs/copia.conf"

  metidoVacio=0
  for item in $(seq 1 $cantidad); do
      cp $ruta $copia &

      nombre=$(obtenerDato "Nombre del dato" "" "")
      uri=$(obtenerDato "Cual es la URI?" "" "NO SE")
      sed "s/URI/$uri/g" -i $copia
      sed "s/NOMBRE/$nombre/g" -i $copia
      sed "s/METHOD/$(elegirMetodoHttp)/g" -i $copia
      cat $copia >> $telegraf &

      zenity --question --text "Quieres llenar los demas con valores por defecto?"
      cantidad=$((cantidad-1))
      if [[ $? -eq 0 ]]; then
        meterVacio "http" $cantidad
        metidoVacio=1
        break
      fi
  done
  
  if [[ $metidoVacio -eq 0 ]]; then
      cat ./telegraf/outputs/influxdb.conf >> $telegraf &
  fi

}
meterMQTT(){
  cantidad=$1
  ruta="telegraf/inputs/mqtt.conf"
  copia="telegraf/inputs/copia.conf"

  metidoVacio=0
  for item in $(seq 1 $cantidad); do
      cp $ruta $copia &

      nombre=$(obtenerDato "Nombre del dato" "" "")
      topic=$(obtenerDato "Cual es el TOPIC" "" "NO SE")
      uri=obtenerDato "Cual es la URI?" "" "NO SE"
      sed "s/URI/$uri/g" -i $copia
      sed "s/NOMBRE/$nombre/g" -i $copia
      sed "s/TOPIC/$topic/g" -i $copia
      cat $copia >> $telegraf &

      zenity --question "Quieres llenar los demas con valores por defecto?"
      cantidad=$((cantidad - 1))
      if [[ $? -eq 0 ]]; then
        meterVacio "mqtt" $cantidad
        metidoVacio=1
        break
      fi
  done
  
  if [[ $metidoVacio -eq 0 ]]; then
      cat ./telegraf/outputs/influxdb.conf >> $telegraf &
  fi

}

meterPLC(){
  cantidad=$1
  meterVacio "plc" $cantidad
  mv ./telegraf/Dockerfile-python ./telegraf/Dockerfile &

  git init
  git submodule add "https://github.com/EnriqueJavierVillarCeaItecam/lector_plc" ./telegraf/lector_plc
  if [[ $? -eq 1 ]]; then

    zenity --error --title "No tienes acceso al repositorio" --text "Cuando tengas acceso al repositorio clonalo en telegraf/ "
  fi
  git submodule update --init --recursive
  git submodule update --remote


}
meterVacio() {
  tipo=$1
  cantidad=$2
  echo $cantidad

  for i in $(seq 1 $cantidad); do
    cat telegraf/inputs/$tipo.conf >> $telegraf
  done

cat telegraf/outputs/influxdb.conf >> $telegraf &


}

cuantosInputs() {
input=$1
if [[ $(echo $inputs | grep $input | wc -l) -eq 1 ]]; then
    cantidad=""
    while [[ -z "$cantidad" ]]; do


      cantidad=$(obtenerDato "Cuantos Inputs "${input^^}" necesitas" "Cantidad de inputs ${input^^}" "0")
      if [[ $? -eq 1 ]]; then
        zenity --question --text "Me tomare como que es 0" --modal
        if [[ $? -eq 0 ]]; then
        cantidad="0"
        fi
      fi
  if [[ ! $cantidad =~ ^[0-9]+$ ]]; then
    zenity --warning --text "Mete un numero anda :,) ┗|｀O′|┛" --modal
    cantidad=""
  fi

done
else 
  cantidad=0
fi

echo $cantidad

}

front(){
   nombre=""
  text="El nombre del Frontend vacio = frontend"
 
while [[ -z $nombre ]]; do
  nombre=$(zenity --entry --title "nombre del frontend" --modal --text "$text")
  if [[ -z $nombre ]]; then
    zenity --question --text "Por defecto es: frontend"
    if [[ $? -eq 0 ]]; then
      nombre="frontend"
    fi
  fi
  if [[ $nombreGrafana -eq 1 && "${nombre,,}" == "grafana" ]]; then
    zenity --error --text "Vas a sobreescribir los archivos de grafana estas seguro?" -extra-button Cancel
    if [[ $? -eq 1 ]]; then
      zenity --info --text "No uses el nombre grafana entonces"
      nombre=""
  fi
  fi
nombreFront=$nombre
done   
if [[ $front -eq 0 ]]; then
pnpm create vite $nombre --template react
cd $nombre && pnpm install && cd ..
fi


    
    for ((i = 0; i < ${#carpetasFront[@]}; i++)); do
        cp -r ${carpetasFront[i]} $nombre 
    done
        
    if [[ $(ls | grep docker | wc -l) -eq 1 ]]; then
        sed -i "s/sistema/$nombre/g" $nombre/service
        sed -i "s/SUPER/$(basename $(pwd))/g" $nombre/service

        cat $nombre/service >> docker-compose.yaml &
        rm $nombre/docker-compose.yaml &
    
    else
        sed -i "s/sistema/$nombre/g" $nombre/docker-compose.yaml
        sed -i "s/SUPER/$(basename $(pwd))/g" $nombre/docker-compose.yaml
        mv $nombre/docker-compose.yaml . &
    fi
    if [[ $(ls | grep Makefile | wc -l) -eq 1 ]]; then
        rm $nombre/Makefile &
    else
        sed -i "s/sistema/$nombre/g" $nombre/Makefile
        sed -i "s/SUPER/$(basename $(pwd))/g" $nombre/Makefile
        mv $nombre/Makefile . &
    fi

    rm $nombre/service &
    echo -e "${AZUL} ${AMARILLO}FRONTEND${NC} ACABADO 📺"
    
}


versiones(){

if [[ $(ls -a | grep .git | wc -l) -ne 1 ]]; then
        git init 1>/dev/null
    fi

git branch -m main
if [[ $api -eq 0 ]]; then
git add . 2>/dev/null 1>/dev/null
if [[ $front -eq 0 ]]; then
  git reset $nombreFront
fi
git commit -m "Estructura basica de proyectos API: $nombre" 1> /dev/null
fi

if [[ $front -eq 0 ]]; then
git add $nombreFront 2>/dev/null 1>/dev/null
git commit -m "Estructura basica de proyectos FRONTEND" 1> /dev/null
fi

if [[ $gemelo -eq 0 ]]; then
  git add . 2>/dev/null 1>/dev/null

  git commit -m "Estructura para GEMELOS"
fi



if [[ $git -eq 1 ]]; then
git remote add origin $repositorio
git push --set-upstream origin main
fi

if [[ $nopushear -eq 0 ]]; then
git push
fi

echo -e "${AZUL}- ${AMARILLO}GIT${NC} ACABADO ${AZUL}🛂|${NC}"

}



dependencias(){
if ! command -v allure &>/dev/null; then
curl -o allure-commandline.zip -L https://github.com/allure-framework/allure2/releases/download/2.13.8/allure-2.13.8.zip &
pid=$!

mkdir -p ~/allure &

wait $pid 
unzip -o allure-commandline.zip -d ~/allure 
rm allure-commandline.zip &

echo 'export PATH=$PATH:~/allure/allure-2.13.8/bin' >> /c/Program\ Files/Git/etc/bash.bashrc
if [[ $? -ne 0 ]]; then
    allurefallado=1
   
fi
fi

cd $nombre
uv add fastapi asyncio sqlalchemy uvicorn asyncpg httpx pytest pytest-tornasync allure-pytest pytest-cov
cd ..

echo -e "${AZUL}- ${AMARILLO}API${NC} ACABADO ⚙"
}



declare -a entidades
entidades() {
  seguir=1
  primeraVez=1
  texto="Introduce una entidad o salir para cotinuar"
  while [[ $seguir -eq 1 ]]; do
    buenas=$(zenity --entry --title "Introduce entidad" --text "$texto" --window-icon=question --modal )
    salirPulsado=$?
    if [[ $salirPulsado -eq 1 || "$buenas" == "Salir" || "$buenas" == "salir"  ]]; then
      seguir=0
    else
      if [[ ! -z "$buenas" && "$buenas" =~ ^[a-zA-Z]+$ ]]; then
        duplicado=0

        for entidad in "${entidades[@]}";
        do
          if [[ "$entidad" == "$buenas" ]]; then
            duplicado=1
            break
          fi
        done
        if [[ $duplicado -eq 0 ]]; then
          echo -e "Entidad introducida: ${AMARILLO}$buenas${NC}"
          entidades+=("$buenas")
        else 
          zenity --error --text "La entidad '$buenas' ya está en la lista. Introduce otra."
        fi
      else
       zenity --error --text "Solo se permiten caracteres alfabéticos (a-z, A-Z)."
      fi 
    fi
    if [[ $seguir -eq 1 && $primeraVez -eq 1 ]]; then
      texto="Introduce otra entidad o salir para continuar"
      primeraVez=0
    fi
  done
  }

crearEntidad() {
  minusculas=${2}
  letra=${minusculas:0:1}
  cp $1/sistema.py $1/$minusculas.py
  capitalizada=${letra^^}${minusculas:1}
  awk -v entidad="papaya" '{gsub("entidades", entidad)}1' "$1/$minusculas.py" > temp && mv temp "$1/$minusculas.py"
  awk -v entidad=$capitalizada '{gsub("ENTIDAD", entidad)}1' "$1/$minusculas.py" > temp && mv temp "$1/$minusculas.py"
  awk -v entidad=$minusculas '{gsub("entidad", entidad)}1' "$1/$minusculas.py" > temp && mv temp "$1/$minusculas.py"
  awk -v entidad="entidades" '{gsub("papaya", entidad)}1' "$1/$minusculas.py" > temp && mv temp "$1/$minusculas.py"

}
aplicarEntidades() {

  imports=""
  include=""
  nombre=$1
  echo "entidades:"
  for entidad in "${entidades[@]}";
  do
    entidad=${entidad,,}
    echo $entidad
    crearEntidad $nombre/entidades/modelos $entidad "modelo"
    crearEntidad $nombre/entidades/schemas $entidad "schema"
    crearEntidad $nombre/routes $entidad "ruta"
    crearEntidad $nombre/services $entidad "service"
    cp -r "$nombre/test/tipo1" "$nombre/test/$entidad" 
    mv "$nombre/test/$entidad/test_test.py" "$nombre/test/$entidad/test_$entidad.py"
    sed "s/entidad/$entidad/g" -i "$nombre/test/$entidad/test_$entidad.py"
    imports+="from routes.$entidad import router as ${entidad}_router\n"
    include+="app.include_router(${entidad}_router)\n"

  done
  rm -rf "$nombre/test/tipo1/" $nombre/entidades/modelos/sistema.py $nombre/entidades/schemas/sistema.py $nombre/routes/sistema.py $nombre/services/sistema.py &
  imports+="from routes.hola import router as hola_router\n"
  include+="app.include_router(hola_router)\n" 
  awk -v imports="$imports" '{gsub("rutas", imports)}1' "${nombre}/main.py" > temp && mv temp "${nombre}/main.py"
  awk -v routes="$include" '{gsub("include", routes)}1' "${nombre}/main.py" > temp && mv temp "${nombre}/main.py" &
  
}

api(){
nombre=""
text="Introduce el nombre de la API"
 
while [[ -z $nombre ]]; do
  nombre=$(zenity --entry --title "nombre de la API" --modal --text "$text")
  if [[ -z $nombre ]]; then
    text="Introduce el nombre de la API - 🚫 vacio"
  fi
done
if ! command -v uv &>/dev/null; then
    pip install uv
fi
uv -v init $nombre -p 3.11.9 &
entidades




for ((i = 0; i < ${#carpetasAPI[@]}; i++)); do
    cp -r ${carpetasAPI[i]} $nombre
done

mv $nombre/docker-compose.yaml .
mv $nombre/Makefile .
cp $nombre/README.md .
sed -i "s/sistema/$nombre/g" $nombre/Dockerfile &
sed -i "s/sistema/$nombre/g" docker-compose.yaml &

sed -i "s/sistema/$nombre/g" Makefile
sed -i "s/SUPER/$(basename $(pwd))/g" Makefile &



(for file in $(find . -iname "*.py" | grep init -v | grep venv -v); do
    sed -i "s/sistema/$nombre/g" "$file"
  done) &
aplicarEntidades $nombre
dependencias $nombre &
mv $nombre/.git .
}
progreso
seleccionarProyectos 

if [[ $(echo $SELECCION | grep "Gemelo" | wc -l) -eq 1 ]]; then
    mapfile -t carpetasGemelos < <(find /proyectos/gemelo -maxdepth 1 | awk 'NR>1{print $0}' )
    gemelo=0
    gemelo
fi

if [[ $(echo $SELECCION | grep "API" | wc -l) -eq 1 ]]; then
    mapfile -t carpetasAPI < <(find /proyectos/api -maxdepth 1 | awk 'NR>1{print $0}' )
    api=0
    api
fi

if [[ $(echo $SELECCION | grep "Front" | wc -l) -eq 1 ]]; then
  if ! command -v pnpm &>/dev/null; then
    echo -e "Instalando ${AZUL_FLOJO}PNPM${NC}"
    curl -fsSL https://get.pnpm.io/install.sh > install
    ./install
    rm install &
    fi
    front=0
    mapfile -t carpetasFront < <(find /proyectos/front -maxdepth 1 | awk 'NR>1{print $0}' )
    front
fi

versiones
if [[ $allurefallado -eq 1 ]]; then
    echo -e "La instalación de ${AMARILLO}ALLURE ${NC} no ha se ha echo correctamente para finalizarla haz esto en una bash abierta como ${AZUL_FLOJO} administrador${NC}" 
    echo -e "echo 'export PATH=\$PATH:~/allure/allure-1.13.8/bin' >> /c/Program\ Files/Git/etc/bash.bashrc"
    fi
    


echo "FIN (*^▽^*)"
