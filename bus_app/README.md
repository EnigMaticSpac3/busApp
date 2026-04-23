# San Antonio Bus Tracker

[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-green.svg)](https://fastapi.tiangolo.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![PostGIS](https://img.shields.io/badge/PostGIS-3.3-orange.svg)](https://postgis.net/)

Un sistema de monitoreo en tiempo real para la ruta interna de San Antonio, Panamá. Este proyecto simula una flota de buses utilizando datos GPS reales de un archivo GPX, proporcionando una experiencia de rastreo precisa y eficiente mediante algoritmos geoespaciales avanzados.

## Tabla de Contenidos

- [Características](#características)
- [Arquitectura Técnica](#arquitectura-técnica)
- [Instalación](#instalación)
- [Flujo de Datos](#flujo-de-datos)
- [API Endpoints](#api-endpoints)
- [Decisiones de Diseño](#decisiones-de-diseño)
- [Uso](#uso)
- [Contribución](#contribución)
- [Licencia](#licencia)

## Características

- **Simulación Realista**: Utiliza datos GPX reales para recrear la ruta exacta de la línea de buses de San Antonio.
- **Flota Dinámica**: Gestiona múltiples buses (actualmente 3) moviéndose simultáneamente por la ruta.
- **Filtrado Inteligente**: Algoritmo de secuencia que muestra solo paradas futuras, evitando confusiones con paradas ya pasadas.
- **Cálculo de ETA**: Estimación de tiempo de llegada basada en distancia geoespacial y velocidad actual.
- **Interfaz Interactiva**: Aplicación Flutter con mapa en tiempo real y actualizaciones cada segundo.
- **Backend Robusto**: API RESTful con FastAPI, soportada por PostgreSQL y PostGIS para operaciones geoespaciales.

## siguientes pasos
De acuerdo a los objetivos iniciales, el script `generate_gtfs.py` ahora produce un feed GTFS mínimo pero válido, con rutas, paradas, calendario y trips. Esto permite una integración futura con plataformas de transporte público y validación formal del feed.
1. Validar con: https://gtfs.org/testing/"
2. Agregar calendar_dates.txt para días festivos."
3. Agregar más trips (servicio cada X minutos)."
4. Subir a Transitland para hacerlo público."

## Arquitectura Técnica

### Backend
- **Framework**: FastAPI (Python) para una API asíncrona y de alto rendimiento.
- **Contenedorización**: Docker para aislamiento y despliegue consistente.
- **Base de Datos**: PostgreSQL con extensión PostGIS para cálculos geoespaciales precisos.
- **Simulación**: Motor GPS asíncrono que mueve buses a través de índices de ruta cada segundo.

### Frontend
- **Framework**: Flutter para una aplicación multiplataforma nativa.
- **Mapeo**: Flutter Map con tiles de OpenStreetMap.
- **Actualización**: Polling HTTP cada segundo para mantener datos en tiempo real.

### Base de Datos
- **Tabla `ruta_bus`**: Almacena puntos secuenciales de la ruta GPS (latitud, longitud, tiempo).
- **Tabla `paradas`**: Puntos de interés estáticos con nombres y ubicaciones geoespaciales.

## Instalación

### Prerrequisitos
- Docker y Docker Compose instalados.
- Puerto 8000 disponible para la API.
- Puerto 5432 disponible para PostgreSQL (opcional, expuesto para desarrollo).

### Pasos Rápidos
1. Clona el repositorio:
   ```bash
   git clone <url-del-repositorio>
   cd bus_app
   ```

2. Navega al directorio del backend:
   ```bash
   cd ../backend_bus_app
   ```

3. Construye y ejecuta los servicios:
   ```bash
   docker-compose up --build
   ```

4. En una terminal separada, inicia la aplicación Flutter:
   ```bash
   cd ../bus_app
   flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
   ```

5. Abre tu navegador en `http://localhost:8080` para ver la aplicación.

La API estará disponible en `http://localhost:8000`, y la base de datos en `localhost:5432`.

## Flujo de Datos

```
[Archivo GPX] --> [Script de Carga (load_gpx.py)] --> [Base de Datos PostgreSQL/PostGIS]
       |                                                       |
       |                                                       |
       v                                                       v
[Simulador GPS (motor_gps)] <----------------------------- [Tabla ruta_bus]
       |                                                       |
       | (Actualiza posiciones cada 1s)                       |
       v                                                       |
[Flota de Buses (Bus-01, Bus-02, Bus-03)]                     |
       |                                                       |
       | (Filtrado por índice de ruta)                        |
       v                                                       |
[API Endpoints] --> [Cálculo de Paradas Cercanas] --> [Estimación ETA]
       |
       v
[Frontend Flutter] --> [Polling HTTP (1s)] --> [Actualización de Mapa y Banner]
```

1. **Carga Inicial**: El archivo GPX se procesa para poblar las tablas `ruta_bus` y `paradas`.
2. **Simulación**: Un motor asíncrono mueve cada bus a través de índices de la ruta, calculando velocidad basada en distancia entre puntos.
3. **Filtrado**: Para cada bus, se calcula el `indice_ruta` más cercano y se filtran paradas futuras.
4. **API**: Endpoints proporcionan datos de ruta, flota y paradas cercanas con ETA.
5. **Frontend**: Polling continuo actualiza marcadores de buses y banner informativo.

## API Endpoints

La API RESTful está construida con FastAPI y soporta CORS para integración frontend.

### GET /api/ruta
Devuelve la lista completa de puntos de la ruta.
- **Respuesta**: `{"puntos": [{"lat": float, "lon": float}, ...]}`

### GET /api/flota
Proporciona el estado actual de toda la flota de buses.
- **Respuesta**: Lista de buses con id, latitud, longitud, velocidad e índice de ruta.
- **Ejemplo**: `[{"id": "Bus-01", "lat": 9.05, "lon": -79.44, "vel_ms": 4.0, "indice": 150}, ...]`

### GET /api/parada-cercana/{id_bus}
Calcula la próxima parada para un bus específico usando filtrado de secuencia.
- **Parámetros**: `id_bus` (string) - ID del bus (e.g., "Bus-01").
- **Respuesta**: `{"parada": string, "distancia": int, "eta": string}`
- **Lógica**: Filtra paradas con `indice_ruta > bus.indice + buffer`, calcula ETA basado en distancia y velocidad.

## Decisiones de Diseño

### Filtrado de Secuencia vs. Proximidad Radial
Un desafío común en sistemas de rastreo de transporte es determinar la "próxima parada" de manera precisa. Un enfoque ingenuo calcularía la parada más cercana por distancia euclidiana o geoespacial, pero esto falla en rutas lineales donde el bus puede estar cerca de paradas ya pasadas o futuras.

**Problema con Proximidad Radial**:
- En una ruta recta, el bus podría estar equidistante entre paradas pasadas y futuras.
- En curvas o rutas complejas, la parada "más cercana" podría ser una ya recorrida.
- Resultado: Información confusa para usuarios, mostrando ETAs negativos o paradas irrelevantes.

**Solución: Filtrado por Índice de Ruta**
- Cada parada se asocia con un `indice_ruta`: el índice del punto de ruta más cercano durante la carga inicial.
- Para un bus en índice `i`, solo se consideran paradas con `indice_ruta > i + buffer` (buffer de 5 para anticipación).
- Esto garantiza que solo se muestren paradas futuras, manteniendo la secuencia lógica de la ruta.
- **Ventajas**: Precisión temporal, evita confusiones, mejora UX en rutas complejas.

### Cálculo de ETA Dinámico
- **Distancia**: Utiliza PostGIS para cálculos geoespaciales precisos (no aproximaciones euclidianas).
- **Velocidad**: Basada en movimiento real del simulador; fallback a 4 m/s si < 1 m/s.
- **Formato**: Minutos enteros o "Menos de 1 min" para granularidad.

### Arquitectura Asíncrona
- El motor GPS corre en una tarea asíncrona separada, actualizando posiciones sin bloquear la API.
- Polling frontend cada segundo mantiene baja latencia sin websockets complejos.

## Uso

1. **Desarrollo**: Ejecuta `docker-compose up` para backend, `flutter run` para frontend.
2. **Producción**: Configura variables de entorno para bases de datos remotas y despliega con Docker.
3. **Extensión**: Agrega más buses modificando la lista `buses` en `main.py`, o integra datos GPS reales.

## Contribución

1. Fork el repositorio.
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`.
3. Commit tus cambios: `git commit -m 'Agrega nueva funcionalidad'`.
4. Push a la rama: `git push origin feature/nueva-funcionalidad`.
5. Abre un Pull Request.

## Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para detalles.
