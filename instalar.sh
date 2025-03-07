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



cp iniciar /c/Program\ Files/Git/mingw64/bin/iniciar
cp -r proyectos/ /proyectos
echo 'export PATH=$PATH:~/AppData/Local/Packages/PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0/LocalCache/local-packages/Python311/Scripts/' >> /c/Program\ Files/Git/etc/bash.bashrc
