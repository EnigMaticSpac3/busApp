#!/bin/bash

# Script para crear ramas según el flujo de trabajo del proyecto
# Uso: ./create-branch.sh [frontend|backend|devops] "descripcion-corta"

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones
usage() {
    echo "Uso: $0 <tipo> <descripcion>"
    echo ""
    echo "Tipos:"
    echo "  frontend  - feature de Flutter/UI"
    echo "  backend   - feature de FastAPI/lógica"
    echo "  devops    - tarea de Docker/infraestructura"
    echo "  fix       - bug fix"
    echo "  refactor  - refactoring"
    echo ""
    echo "Ejemplos:"
    echo "  $0 frontend 'aplicar-paleta-colores'"
    echo "  $0 backend 'agregar-websocket-flota'"
    echo "  $0 devops 'docker-multi-stage'"
    exit 1
}

# Validar argumentos
if [ $# -lt 2 ]; then
    usage
fi

TIPO=$1
DESCRIPCION=$2

# Mapeo de tipos a prefijos
case $TIPO in
    frontend) PREFIJO="feat/frontend" ;;
    backend)  PREFIJO="feat/backend" ;;
    devops)   PREFIJO="chore/devops" ;;
    fix)      PREFIJO="fix" ;;
    refactor) PREFIJO="refactor" ;;
    *)        echo -e "${RED}Tipo inválido: $TIPO${NC}"; usage ;;
esac

# Sanitizar descripción (reemplazar espacios con guiones, lowercase)
DESCRIPCION_SANEADA=$(echo "$DESCRIPCION" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')

# Crear nombre de rama
FECHA=$(date +%Y%m%d)
NOMBRE_RAMA="${PREFIJO}-${FECHA}-${DESCRIPCION_SANEADA}"

echo -e "${YELLOW}Creando rama: ${NOMBRE_RAMA}${NC}"

# Actualizar develop primero
echo -e "${YELLOW}Actualizando develop...${NC}"
git checkout develop 2>/dev/null || git checkout -b develop
git pull origin develop 2>/dev/null || echo "No se pudo pull, continuando..."

# Crear y cambiar a la rama
git checkout -b "$NOMBRE_RAMA"

echo -e "${GREEN}✓ Rama '$NOMBRE_RAMA' creada y activada${NC}"
echo ""
echo "Próximos pasos:"
echo "  1. Hacer tus cambios"
echo "  2. git add ."
echo "  3. git commit -m 'feat($TIPO): $DESCRIPCION'"
echo "  4. git push -u origin $NOMBRE_RAMA"
echo ""
echo "Para crear PR: usar interfaz de GitHub/GitLab"