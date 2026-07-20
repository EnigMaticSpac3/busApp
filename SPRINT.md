# SPRINT.md — Transita
# Fuente de verdad del orquestador. Actualizar después de cada tarea completada.

## 📊 Estado General del Proyecto

```
v1  ✅  Mapa básico, ruta E598, simulación GPS
v2  ✅  Sesiones dinámicas, crowdsourcing, validado en campo
v3  ✅  Menú de rutas, ubicación usuario, navegación tabs
v4  ✅  WebSocket, animaciones suaves, modo conductor básico
v5A 🔄  Modo conductor: ~85% funcional (SPRINT EN REVISIÓN)
v5B ⬜  Notificaciones push (FCM) — depende de v5A
v5C ⬜  Planificador OTP — depende de v5B
v5D ⬜  Deployment Fly.io — depende de v5A validado
```

---

## 🧹 Deuda Técnica (resolver antes o durante v5)

| ID | Descripción | Agente | Impacto | Decisión |
|----|-------------|--------|---------|----------|
| DT-01 | Dos paletas compitiendo: AppColors (#283C90) vs AppConfig (#0256a4) | @frontend | ~~ALTO~~ | ✅ Resuelto. AppColors es la única fuente. |
| DT-02 | 6 archivos legacy sin uso: bus_marker.dart, bus_marker_animated.dart, eta_banner.dart, eta_badge.dart, bus_model.dart, conductor_service.dart | @frontend | ~~MEDIO~~ | ❌ **No eliminar.** Ya actualizados a AppColors. Pueden ser útiles como respaldo. Marcar como "disponibles" no como "basura". |
| DT-03 | Backend monolítico: todo en main.py sin separación de capas | @backend | MEDIO | ⬜ Pendiente |
| DT-04 | /api/rutas/{ruta_id}/paradas ignora el ruta_id (hardcoded) | @backend | ~~MEDIO~~ | ✅ Resuelto. Ahora filtra paradas por ruta_id real desde GTFS. Rama: `fix/backend-corregir-paradas-por-ruta`. |
| DT-05 | Sin state management: todo setState, ~15 vars por screen | @frontend | BAJO | 🟡 Baja prioridad. Aplazar. |
| DT-06 | Lógica GPS duplicada en conductor_service.dart y conductor_screen.dart | @frontend | ~~ALTO~~ | 🟡 Baja prioridad. `conductor_service.dart` no interfiere. Unificar solo si se refactoriza. |
| DT-07 | URL ngrok hardcodeada en app_config.dart | @frontend | ~~ALTO~~ | ✅ Resuelto. `backendUrl` se lee desde `.env` vía `flutter_dotenv`. Rama: `feat/frontend-url-backend-env-variable`. |

---

## 🎯 Sprint v5A — Modo Conductor (Priorización Revisada)

> ⚠️ **Nota:** Este sprint se re-priorizó según evaluación de código real y QA en campo. El orden ahora es: estabilizar core → escalar → features nuevas.

### Fase 0 — Estabilizar el Core 🔴 (PRIMERO)

| # | Ticket | Agente | Prioridad | Depende de | Nota |
|---|--------|--------|-----------|------------|------|
| T-21 | Validar WebSocket + GPS en campo controlado (QA-07) | @frontend + @backend | 🔴 Crítica | QA-07 | Prueba con 3 dispositivos (1 conductor, 2 pasajeros). Medir pérdidas >3s. Apagar internet 10s en conductor y medir reconexión. |
| T-22 | Aplicar fix: re-enviar última posición GPS si falla Geolocator | @frontend | 🔴 Crítica | T-21 | ✅ Resuelto. Si falla GPS, re-envía `_currentPosition`. Rama: `feat/frontend-20260615-fix-reenvio-ultima-posicion-gps`. |
| T-03 | Mover URL backend a variable de entorno (no hardcoded) | @frontend | 🔴 Crítica | ninguna | Si ngrok cambia la URL, la app deja de funcionar completamente. Resolver antes de cualquier feature nuevo. |
| T-23 | Crear endpoint POST /api/sesion-conductor/fin | @backend | 🟡 Alta | T-21 | ✅ Resuelto. Endpoint creado, idempotente, con broadcast WebSocket. Rama: `feat/backend-endpoint-fin-sesion-conductor`. |
| T-24 | Corregir DT-04: /api/rutas/{ruta_id}/paradas usa ruta_id real | @backend | 🟡 Alta | ninguna | ✅ Resuelto. Ahora filtra paradas por ruta_id desde GTFS. Rama: `fix/backend-corregir-paradas-por-ruta`. |
| T-27 | Evitar duplicación de sesión conductor al navegar hacia atrás | @frontend | 🟡 Alta | ninguna | ✅ Resuelto. `PopScope` intercepta back y llama a `_cerrarSesion()`. Rama: `feat/frontend-20260615-fix-navegacion-conductor-sesion-duplicada`. |

### Fase 1 — Escalar y Pulir 🟢

| # | Ticket | Agente | Prioridad | Depende de | Nota |
|---|--------|--------|-----------|------------|------|
| T-25 | Script simulación de múltiples buses en flota | @backend | 🟢 Media | T-21 | Script Python que inyecta posiciones vía `POST /api/contribuir-ubicacion` con distintos `usuario_id`. Demostrar que la arquitectura soporta >1 bus. |
| T-26 | Búsqueda local GTFS (conectar AppSearchBar) | @frontend + @backend | 🟢 Media | T-21, T-03 | Cargar routes.txt/stops.txt en backend. Endpoint `/api/buscar?q=...`. Conectar `AppSearchBar` existente a ese endpoint. Sin Google, sin costo. |
| T-11 | Limpiar docker-compose y dependencias | @devops | 🟢 Baja | ninguna | Independiente. |
| T-12 | Preparar fly.toml para deployment futuro | @devops | 🟢 Baja | T-11 | Depende de T-11. |
| T-28 | Nuevo endpoint `/api/eta-parada/{parada_id}` + mejorar `GET /api/ruta` con `ruta_id` | @backend | 🟡 Alta | ninguna | ✅ Resuelto. `GET /api/ruta` devuelve `ruta_id`. Nuevo endpoint `GET /api/eta-parada/{parada_id}` devuelve buses con ETA. Rama: `feat/backend-20260719-endpoint-eta-parada`. |
| T-29 | ETA real al tocar parada en mapa (B+C): marcadores zoom-dependent + eliminar ETA flotante | @frontend | 🟡 Alta | T-28 | ✅ Resuelto. Paradas visibles en zoom≥15, tap abre sheet con ETAs. CollapsedEtaCard eliminado. Rama: feat/frontend-20260719-eta-parada-en-mapa. |
| T-31 | Rebranding completo a "Transita" con paleta Canal (azul #004F7C, naranja #F59D3D, rojo #E84C2B). Plus Jakarta Sans + JetBrains Mono. Nuevos spacing/radius/shadows. | @frontend | 🟡 Alta | ninguna | ✅ Resuelto. Nueva paleta Canal (azul #004F7C, naranja #F59D3D, rojo #E84C2B). Plus Jakarta Sans + JetBrains Mono. App rebautizada a "Transita". Rama: feat/frontend-20260719-rebranding-transita-canal. |

### Fase 2 — Aplazado / Resuelto (v5A original)

| # | Ticket | Agente | Decisión Final |
|---|--------|--------|----------------|
| T-00 | Unificar paleta en AppColors | @frontend | ✅ Resuelto por V01 |
| T-01 | Eliminar 6 archivos legacy | @frontend | ❌ No hacer. Ya actualizados a AppColors. Sirven como respaldo. |
| T-02 | Unificar GPS en ConductorService | @frontend | 🟡 Aplazar. `conductor_service.dart` no interfiere. Unificar solo si se refactoriza conductor_screen. |
| T-04 | Endpoint POST /api/auth/conductor (PIN 4 dígitos) | @backend | ✅ Resuelto. Ya existe en main.py:646. |
| T-05 | Endpoint validar-token | @backend | ❌ Diferir. PIN por sesión es suficiente para MVP. |
| T-06 | LoginScreen con PIN 4 dígitos | @frontend | ✅ Resuelto. `conductor_login_screen.dart` funciona. |
| T-07 | Detección automática de rol | @frontend | ❌ Diferir. Botón manual en RutasScreen es suficiente. Futuro: QR. |
| T-08 | Background location (Foreground Service) | @frontend | ⬜ Aplazar. GPS actual funciona con app abierta. |
| T-09 | Dead Man's Switch (>30s expira) | @backend | 🟡 Revisado. Código actual usa 300s. **Decisión: mantener 300s.** 30s genera falsos positivos. |
| T-10 | Optimizar batería (frecuencia variable) | @frontend | ⬜ Aplazar. Depende de T-08. |

## 🎯 Sprint v5B — Notificaciones Push (DESPUÉS de v5A)

| # | Ticket | Agente | Estado | Depende de |
|---|--------|--------|--------|------------|
| T-13 | Integrar Firebase FCM en Flutter | @frontend | ⬜ | v5A completo |
| T-14 | Geofencing del servidor: bus a 500m → push a pasajeros | @backend | ⬜ | T-13 |
| T-15 | Alerta en pantalla bloqueada sin abrir la app | @frontend | ⬜ | T-13 |

---

## 🎯 Sprint v5C — Planificador OTP (DESPUÉS de v5B)

| # | Ticket | Agente | Estado | Depende de |
|---|--------|--------|--------|------------|
| T-16 | Configurar OpenTripPlanner con GTFS local + OSM Panamá | @devops | ⬜ | v5B completo |
| T-17 | Endpoint FastAPI que consulta OTP | @backend | ⬜ | T-16 |
| T-18 | SearchBar A→B en Flutter con resultados de OTP | @frontend | ⬜ | T-17 |

---

## 🎯 Sprint v5D — Deployment (CUANDO v5A esté validado en campo)

| # | Ticket | Agente | Estado | Depende de |
|---|--------|--------|--------|------------|
| T-19 | Deployment en Fly.io | @devops | ⬜ | v5A validado |
| T-20 | Estandarizar IDs de rutas (SA_INTERNAL → E598) | @backend | ⬜ | T-19 |

---

## 📝 Historial de Cambios

| Fecha | Cambio | Responsable |
|-------|--------|-------------|
| 2026-05 | Sprint v5 iniciado | Jorge |
| 2026-05 | Deuda técnica documentada | Orquestador |
| 2026-05 | QA-06 y QA-07 documentados como observaciones de campo | Orquestador |
| 2026-06 | T-03 completado: URL backend a variable de entorno + DT-07 resuelto | Orquestador |
| 2026-06 | T-24 completado: endpoint /api/rutas/{ruta_id}/paradas ahora usa ruta_id real + DT-04 resuelto | Orquestador |
| 2026-06 | T-23 completado: endpoint POST /api/sesion-conductor/fin creado | Orquestador |
| 2026-06 | T-22 completado: fix re-envío última posición GPS en conductor | Orquestador |
| 2026-06 | T-27 completado: PopScope intercepta back en ConductorScreen, evita sesiones huérfanas | Orquestador |
| 2026-06 | T-28 y T-29 creados: ETA real por parada en mapa + marcadores zoom-dependent | Orquestador |
| 2026-07 | T-28 completado: endpoint eta-parada + ruta_id en GET /api/ruta | Orquestador |
| 2026-07 | T-29 completado: ETA real al tocar parada en mapa + eliminado CollapsedEtaCard | Orquestador |
| 2026-07 | T-31 creado: rebranding a Transita con paleta Canal | Orquestador |
| 2026-07 | T-31 completado: rebranding a Transita con paleta Canal | Orquestador |

---

## 🧪 Observaciones QA (Validación en Campo)

### QA-06 — Buses duplicados (conductor + crowdsourcing)

**Estado:** ✅ Cerrada (no bloqueante, comportamiento esperado)

**Observación:** Durante prueba real se detectaron 2 buses simultáneos en el mapa — uno generado por sesión conductor y otro por crowdsourcing desde otro dispositivo.

**Hipótesis:** El backend almacena conductor y crowdsourcing en diccionarios separados (`sesiones_conductor` y `sesiones_activas`). Ambos se mezclan en `_get_flota_data_completa()` sin deduplicación. Cada uno tiene distinto `session_id`, por lo que el frontend los renderiza como entidades independientes.

**Evidencia:**
- `/api/flota` responde 200 OK con ambas entidades
- Conductor: `bus_id = "Conductor-XXXX"`
- Crowdsourcing: `bus_id = "Bus-YYYY"`
- La exclusión por `session_id` (línea 486 de main.py) nunca se activa porque los IDs vienen de endpoints distintos

**Mejora futura sugerida:**
- Deduplicar por `ruta_id + proximidad geográfica < 50m`
- Agregar campo `tipo_origen: "conductor" | "crowdsourcing"` al modelo de flota
- Etiquetar marcadores según origen

---

### QA-07 — Desaparición temporal del bus conductor en el mapa

**Estado:** ✅ Cerrada (hipótesis documentada, monitorear)

**Observación:** El bus conductor desapareció del mapa brevemente y reapareció sin intervención. El dispositivo conductor permanecía activo.

**Causas posibles (ordenadas por probabilidad):**

| # | Causa | Probabilidad | Detalle |
|---|-------|-------------|---------|
| 1 | GPS intermitente en dispositivo conductor | 🟡 Media | Si `Geolocator.getCurrentPosition()` falla (túnel, edificios), el `try/catch` en `conductor_screen.dart:156-158` no reenvía última posición conocida. El backend mantiene su último dato, pero si el conductor inició hace poco, podría tener lat=0/lon=0 y el marcador se filtra en `bus_marker_widget.dart:12`. |
| 2 | Reconexión WebSocket | 🟡 Media | En `websocket_service.dart:53`, al reconectar se hace `_flota.clear()` + `_flota.addAll()`. Ventana de ~3s sin datos frescos. Polling HTTP cada 2s lo restaura rápido. |
| 3 | Race HTTP polling vs WebSocket | 🟢 Baja | Ambos escriben `_flota` vía `setState`. El último en escribir gana, pero ambos incluyen al conductor. |
| 4 | Latencia ngrok | 🟢 Baja | La URL `ngrok-free.dev` añade latencia variable en horas pico. |

**Mejora sugerida (baja prioridad):**
En `conductor_screen.dart`, si `Geolocator.getCurrentPosition()` falla, re-enviar la última posición conocida en vez de no enviar nada:
```dart
try {
  final position = await Geolocator.getCurrentPosition();
  _currentPosition = position;
  await _api.sendConductorPosition(..., position.latitude, position.longitude, position.speed);
} catch (e) {
  if (_currentPosition != null) {
    await _api.sendConductorPosition(..., _currentPosition!.latitude, _currentPosition!.longitude, _currentPosition!.speed);
  }
  // ...
}
```

---

## ⚠️ Notas para el Orquestador

1. **Fase 0 primero, siempre.** Ningún ticket de Fase 1 puede comenzar hasta que T-21, T-22, T-03 estén completados y validados.
2. **T-21 requiere plan de prueba escrito** antes de ejecutar. Definir métricas: tiempo máximo sin actualización, tiempo de reconexión WebSocket, tasa de pérdida de GPS.
3. **T-03 es independiente** — puede asignarse en paralelo con T-23 o T-24 si hay agentes disponibles.
4. **No iniciar v5B hasta que** el Dead Man's Switch esté validado en campo contra múltiples buses reales.
5. **Dead Man's Switch: mantener 300s.** No bajar a 30s sin evidencia de abuso en campo. 30s genera falsos positivos (túneles, semáforos, pérdida temporal de GPS).
6. **Archivos legacy (DT-02): no eliminar.** Ya están actualizados a AppColors. No estorban y sirven como respaldo.
7. **T-07 (detección de rol): diferir.** Acceso manual por botón en RutasScreen es suficiente para MVP. Futuro: QR u otro método de ingreso rápido.
8. **Prueba de campo con 3 dispositivos** es el gate para pasar de Fase 0 a Fase 1.