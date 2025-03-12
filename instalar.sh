#!/bin/bash
 ROJO='\033[0;31m'
 VERDE='\033[0;32m'
 AMARILLO='\033[0;33m'
 AZUL='\033[0;34m'
 NC='\033[0m'
 AZUL_FLOJO='\033[0;36m'
if ! net session > /dev/null 2>&1; then
  echo -e "Falta de${ROJO} permisos${NC}"
  echo -e "Ejecuta este script con permisos de${VERDE} administrador${NC}"
  exit -1
fi
instalarAllure(){
    echo -e "Instalando ${AZUL_FLOJO}Allure${NC}"
curl -o allure-commandline.zip -L https://github.com/allure-framework/allure2/releases/download/2.13.8/allure-2.13.8.zip &
pid=$!

mkdir -p ~/allure &

wait $pid 
unzip -o allure-commandline.zip -d ~/allure 
rm allure-commandline.zip &

echo 'export PATH=$PATH:~/allure/allure-2.13.8/bin' >> /c/Program\ Files/Git/etc/bash.bashrc
}
instalarPnpm(){
    echo -e "Instalando ${AZUL_FLOJO}PNPM${NC}"
    curl -fsSL https://get.pnpm.io/install.sh > install
    ./install
    rm install
}

instalarScoop(){
  powershell "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
  powershell "Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression"
}


instalarZenity (){
  if ! command -v scoop &>/dev/null; then
    instalarScoop
  fi
  scoop install https://ncruces.github.io/scoop/zenity.json
  powershell "Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser" &
}
if ! command -v zenity &>/dev/null; then
  instalarZenity &
fi

if ! command -v allure &>/dev/null; then
  instalarAllure &
fi

if ! command -v uv &>/dev/null; then
    echo -e "Instalando ${AZUL_FLOJO}UV${NC}"
    pip install uv &
fi
if ! command -v pnpm &>/dev/null; then
  instalarPnpm &
    fi


rm -rf /proyectos
cp iniciar.sh /c/Program\ Files/Git/mingw64/bin/iniciar &
cp -r proyectos/ /proyectos &
echo 'export PATH=$PATH:~/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0/LocalCache/local-packages/Python311/Scripts/' >> /c/Program\ Files/Git/etc/bash.bashrc &

echo -e "Instalación acabada, puede que tengas que ${AMARILLO}reiniciar${NC} la terminal"
