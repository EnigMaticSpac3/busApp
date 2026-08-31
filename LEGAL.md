# Consideraciones Legales y de Privacidad

## ⚠️ IMPORTANTE: Datos Obtenidos por Reverse Engineering

Este proyecto accede a la API de MiBus mediante análisis de ingeniería inversa (reverse engineering) del APK de la aplicación móvil. Los datos obtenidos incluyen información sensible sobre conductores y operaciones de transporte.

### Origen de los Datos

| Dato | Origen | Propiedad | Sensibilidad |
|------|--------|----------|--------------|
| **Stops (paradas)** | API MiBus (`/stops/nearer-stops`) | MiBus Panama | Pública |
| **Rutas (geometrías)** | API MiBus (`/line/journey-polyline-v2`) | MiBus Panama | Pública |
| **Horarios** | API MiBus (`/line/get-line-timing`) | MiBus Panama | Pública |
| **GPS en vivo (buses)** | API MiBus (`/buses/get-bus-details`) | Conductores / MiBus | **PRIVADA** ⚠️ |
| **Datos de conductor** | Derivado de GPS | Conductores | **PRIVADA** ⚠️ |
| **Polylines** | Posiblemente Google Maps | Google / MiBus | Licencia dual |

### Restricciones Identificadas

1. **Acceso sin autorización oficial**
   - Token Bearer descubierto mediante reverse engineering (APK decompilada)
   - No hay acuerdo de ToS (Terms of Service) firmado con MiBus
   - Acceso puede ser revocado unilateralmente sin aviso

2. **Datos de conductores (privacidad)**
   - GPS en vivo = datos personales de conductores
   - Potencial violación de privacidad (similar a GDPR)
   - MiBus podría ser responsable de proteger esta data

3. **Licencia de datos**
   - No hay licencia explícita que permita re-distribución
   - Uso probablemente restringido a operaciones internas de MiBus
   - Publicar estos datos en GitHub = posible violación

4. **Rate limiting y detección**
   - La API podría implementar throttling sin aviso
   - Uso intensivo (polling > 100 req/hora) podría disparar ban
   - IP comercial (AWS, datacenter) es red flag para MiBus

### Casos de Uso PERMITIDOS

✅ **Para este proyecto (académico):**
- Análisis exploratorio con fines educativos
- Almacenamiento local de datos extraídos
- Visualizaciones y métricas agregadas
- Documentación del reverse engineering
- Demostración en clase (no publicada)

### Casos de Uso PROHIBIDOS

❌ **No hacer:**
- Publicar datos de GPS en vivo de buses en repositorio público
- Crear servicio comercial que expone API de MiBus
- Vender acceso a datos de MiBus
- Usar datos en aplicación de producción sin permiso
- Ejecutar polling constante (> 1000 req/día)
- Compartir el Bearer token públicamente

### Medidas de Mitigación Implementadas

| Medida | Descripción |
|--------|------------|
| **Extracción única** | No polling automático en desarrollo |
| **Rate limiting manual** | Delays 0.3-0.5s entre requests |
| **IP no comercial** | Ejecución desde laptop personal, no datacenter |
| **Datos locales** | Extracción guardada localmente, no en streaming |
| **Alcance limitado** | Solo San Miguelito, no país completo |
| **Documentación** | Riesgos explícitamente documentados |

### Requisitos Legales Futuros (Para Producción)

Si este proyecto escala a producción:

1. **Contactar a MiBus oficialmente**
Solicitar API key oficial
Negociar términos de servicio
Establecer SLA (Service Level Agreement)
Definir límites de rate limiting

2. **Anonimizar datos de conductores**
Remover o hashear GPS en vivo
Agregar datos por zona/ruta, no individual
Implementar data retention policy

3. **Considerar alternativas open source**
OpenTransit Data
OpenStreetMap (GTFS feeds)
APIs públicas de ciudades (si existen)

4. **Cumplimiento normativo**
Ley de Protección de Datos de Panamá (si aplica)
Términos de uso explícitos para usuarios finales
Política de privacidad publicada
Consentimiento informado de conductores

---

## ⚠️ DISCLAIMER

Este proyecto es un ejercicio de **ingeniería inversa con fines educativos**.
The developers of this project are NOT responsible for:

Unauthorized use of MiBus API
Breach of ToS if any exists
Privacy violations if GPS data is misused
Service disruption or legal action by MiBus
Use at your own risk. Comply with local laws and MiBus terms of service.


---

## Historial de Cambios

- **2026-06-08**: Documento creado tras análisis de riesgos
- **Status**: ⚠️ Requiere revisión legal antes de producción