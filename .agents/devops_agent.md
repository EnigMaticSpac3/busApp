# Role: DevOps & Infrastructure Specialist
# Context: Dockerization & Deployment - San Antonio Bus Tracker
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
- Optimizar imágenes Docker (multi-stage, menor tamaño)
- Mejorar docker-compose.yml (redes, volúmenes, healthchecks)
- Crear .dockerignore eficiente
- Configurar variables de entorno y secretos

## 📁 Archivos Bajo Tu Dominio
- `backend_bus_app/Dockerfile` - Imagen de la API
- `backend_bus_app/docker-compose.yml` - Orquestación
- `backend_bus_app/.env` - Variables de entorno
- `backend_bus_app/requirements.txt` - Dependencias Python
- `.dockerignore` (raíz del proyecto)

## 🔴 Problemas Identificados

### Dockerfile Actual (líneas 1-12)
```dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y gcc  # ← innecesario
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .  # ← copia TODO incluyendo venv/
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```
**Problemas:**
- No hay multi-stage build
- gcc instalado pero no necesario (no hay compiled extensions)
- Copia todo el directorio (incluye venv/, __pycache__/, .env)
- Tamaño de imagen ~500MB+

### docker-compose.yml Actual
```yaml
services:
  api:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./app:/app  # ← monta app/ sobreescribiendo lo copiado
    env_file:
      - .env
    # depends_on commented out - no espera a DB
  db:
    image: postgis/postgis:15-3.3
    # ... config OK
```
**Problemas:**
- Volumen `./app:/app` sobreescribe lo copiado en build
- No hay red definida entre servicios
- No hay volumen para GTFS (se copia en build, no actualizable en runtime)
- PostGIS corre pero NO se usa en código

## 🔧 Quick Wins Activos

### 1. Multi-stage Dockerfile
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runner
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY app/ /app/
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```
**Resultado**: Imagen ~150MB (vs ~500MB)

### 2. .dockerignore
```
venv/
__pycache__/
*.pyc
.git/
.gitignore
.env
*.md
LICENSE
bus_app/
.DS_Store
```

### 3. docker-compose.yml optimizado
- Agregar red aislada `backend_network`
- Comentar o eliminar volumen que sobreescribe
- Descomentar depends_on para esperar DB

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama nueva: `git checkout -b chore/devops-nombre-tarea`
- **ANTES** de build: verificar con `docker build --no-cache`
- PostGIS debe estar en red aislada con la API
- GTFS puede montarse como volumen (permite updates sin rebuild)

## ✅ Definition of Done
- [ ] `docker-compose up --build` funciona sin errores
- [ ] Imagen final < 200MB
- [ ] .dockerignore excluye venv/ y archivos innecesarios
- [ ] API responde en localhost:8000
- [ ] Commit sigue: `chore(devops): descripción`
- [ ] Rama lista para merge