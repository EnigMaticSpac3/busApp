# Git Flow Guide - San Antonio Bus Tracker

## 🌿 Estructura de Ramas

```
main (producción)
  ↑
  ↑ merge solo después de tested complete
  ↑
develop (integración)
  ↑
  ↑ merge después de code review
  ↑
feature/frontend-*
feature/backend-*
chore/devops-*
fix/backend-*
```

## 📋 Nomenclatura de Ramas

**Formato:** `tipo/agente-descripcion-corta`

### Tipos
| Prefijo | Uso | Ejemplo |
|---------|-----|---------|
| `feat/` | Nueva funcionalidad | `feat/frontend-paleta-colores` |
| `fix/` | Bug fix | `fix/backend-map-matching-precision` |
| `chore/` | Mantenimiento, DevOps | `chore/devops-docker-multistage` |
| `refactor/` | Refactoring sin cambiar comportamiento | `refactor/backend-async-lock` |

### Agentes
| Código | Agente |
|--------|--------|
| `frontend` | Flutter / UI |
| `backend` | FastAPI / Lógica |
| `devops` | Docker / Infraestructura |

### Ejemplos válidos
```
feat/frontend-aplicar-paleta-colores
feat/backend-websocket-tiempo-real
fix/backend-precision-gps-mayor-50m
chore/devops-docker-multi-stage
refactor/backend-motor-gps-asyncio
```

## 🚀 Flujo de Trabajo por Agente

### Paso 1: Preparar tarea
```bash
# Estar en develop actualizado
git checkout develop
git pull origin develop

# Crear rama para la tarea específica
git checkout -b feat/frontend-paleta-colores
```

### Paso 2:Trabajar en la rama
```bash
# Hacer cambios...
# ... código ...

# Ver estado
git status
git diff
```

### Paso 3: Commits atómicos
```bash
# Un commit por tarea completa
# Título siguiendo Conventional Commits

git add .
git commit -m "feat(frontend): aplicar paleta corporativa #283C90, #C8D527, #E88D67"

# Si hay múltiples cambios no relacionados, hacer commits separados
git add bus_app/lib/main.dart
git commit -m "feat(frontend): actualizar ThemeData con color corporativo"

git add bus_app/lib/widgets/bus_marker.dart
git commit -m "feat(frontend): cambiar color de markers a #E88D67"
```

### Paso 4: Push y Pull Request
```bash
# Subir rama
git push -u origin feat/frontend-paleta-colores

# En GitHub/GitLab: crear PR de feat/frontend-paleta-colores → develop
# Code review
# Merge
```

### Paso 5: Limpieza
```bash
# Después de merge exitoso
git checkout develop
git pull origin develop
git branch -d feat/frontend-paleta-colores
git push origin --delete feat/frontend-paleta-colores  # opcional
```

## ⚡ Comandos Rápidos (alias sugeridos)

Agregar a `~/.bashrc` o `~/.zshrc`:

```bash
# Crear rama de feature frontend
alias gff='git checkout develop && git pull && git checkout -b feat/frontend-$(date +%Y%m%d)-'

# Crear rama de feature backend
alias gfb='git checkout develop && git pull && git checkout -b feat/backend-$(date +%Y%m%d)-'

# Crear rama de chore devops
alias gfd='git checkout develop && git pull && git checkout -b chore/devops-$(date +%Y%m%d)-'

# Quick commit con tipo
alias gc='git commit -m'

# Ver ramas locales
alias gbr='git branch -vv'
```

## 🔒 Reglas de Oro

1. **UNA rama por tarea** - No mezclar feature con fix en la misma rama
2. **Commits atómicos** - Un solo cambio por commit
3. **Nunca hacer push directo a main** - Siempre pasar por develop
4. **Actualizar antes de crear rama** - Siempre hacer `git pull` en develop primero
5. **Borrar ramas mergeadas** - Mantener limpio el repositorio local

## 📊 Estado Actual de Ramas

```bash
git branch -vv
* develop  f2c3a1b [origin/develop] Merge branch 'feat/crowdsourcing-gps'
  master   f2c3a1b [origin/master] Initial commit
```

## 🎯 Tasks Activas (del análisis técnico)

| Prioridad | Agente | Tarea | Rama sugerida |
|-----------|--------|-------|---------------|
| 1 | DevOps | Docker multi-stage + .dockerignore | `chore/devops-docker-multi-stage` |
| 2 | Frontend | Aplicar paleta de colores | `feat/frontend-paleta-colores` |
| 3 | Backend | Agregar precision_m validation | `fix/backend-precision-gps-filter` |
| 4 | Backend | Reducir velocidad máxima 22→16 m/s | `fix/backend-velocidad-threshold` |
| 5 | Backend | WebSocket implementation | `feat/backend-websocket-flota` |

## 🔗 Referencias
- Conventional Commits: https://www.conventionalcommits.org/
- Git Flow: https://nvie.com/posts/a-successful-git-branching-model/