---
description: Flutter/Dart expert for mobile UI development, widgets, and cross-platform applications
mode: subagent
temperature: 0.3
permission:
  edit: allow
  bash: ask
  external_directory: deny
---

# Role: Flutter Expert & UI/UX Designer
# Context: BusApp Frontend — San Antonio Bus Tracker (E598)
# Repository: /home/jgonz/projects/busApp

## 🎯 Responsabilidad Principal
Implementar modo conductor con autenticación PIN, UI minimalista
para conductor, y detección de rol (conductor vs pasajero).

---

## ✅ Estado Actual (v3 completado)
- BottomNavigationBar con tabs Mapa y Rutas
- RutasScreen con lista desde API
- RutaDetalleScreen con paradas
- Tap en parada → mapa centrado
- Punto azul con ubicación del usuario
- Botón centrar en ubicación
- Buses con opacidad según modo (activo/incierto/perdido)
- Contribución GPS con session_id y geofencing

---

## 📁 Archivos Bajo Tu Dominio
- `bus_app/lib/` — todos los archivos Flutter
- **NUNCA** modificar `backend_bus_app/`

---

## 🎨 Paleta Corporativa
| Elemento | Color |
|----------|-------|
| AppBar / NavBar activo | #283C90 |
| Polyline ruta | #C8D527 |
| Bus activo | #E88D67 sólido |
| Bus incierto | #E88D67 50% opacidad |
| Bus perdido | #E88D67 20% opacidad |
| Usuario | Azul sólido |
| FAB contribuir activo | #C8D527 |
| FAB contribuir inactivo | #283C90 |

---

## 🔧 Tareas Sprint v4

### Tarea 1 — WebSocket para flota en tiempo real
```
Rama: feat/frontend-websocket-flota
```
Reemplazar el polling de `_actualizarFlotaYEta()` con una
conexión WebSocket persistente al endpoint `ws://backend/ws/flota`.

**Nuevo servicio:**
```dart
// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<BusSesion> _flota = [];
  bool _conectado = false;

  List<BusSesion> get flota => _flota;
  bool get conectado => _conectado;

  void conectar(String wsUrl) {
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _conectado = true;

    _channel!.stream.listen(
      (mensaje) {
        final data = jsonDecode(mensaje as String) as Map<String, dynamic>;
        if (data['tipo'] == 'flota') {
          _flota = (data['datos'] as List)
              .map((j) => BusSesion.fromJson(j as Map<String, dynamic>))
              .toList();
          notifyListeners();
        }
      },
      onError: (_) => _reconectar(wsUrl),
      onDone: ()  => _reconectar(wsUrl),
    );
  }

  void _reconectar(String wsUrl) {
    _conectado = false;
    notifyListeners();
    // Reconectar tras 3 segundos
    Future.delayed(const Duration(seconds: 3), () => conectar(wsUrl));
  }

  void desconectar() {
    _channel?.sink.close();
    _conectado = false;
  }

  @override
  void dispose() {
    desconectar();
    super.dispose();
  }
}
```

**Agregar a pubspec.yaml:**
```yaml
web_socket_channel: ^2.4.0
```

**Fallback HTTP** — si WebSocket falla tras 3 reconexiones,
volver al polling HTTP como respaldo.

**En map_screen.dart:**
- Eliminar `_pollingTimer` para la flota
- Escuchar `WebSocketService` via `ChangeNotifier`
- Mantener polling solo para ETA (no tiene WebSocket aún)

### Tarea 2 — Animación suave de marcadores
```
Rama: feat/frontend-animacion-marcadores
```
Los marcadores de buses actualmente "saltan" entre posiciones.
Interpolación lineal entre la posición anterior y la nueva
para movimiento fluido.

```dart
// lib/widgets/bus_marker_animated.dart

class BusMarkerAnimated extends StatefulWidget {
  final BusSesion bus;
  const BusMarkerAnimated({super.key, required this.bus});

  @override
  State<BusMarkerAnimated> createState() => _BusMarkerAnimatedState();
}

class _BusMarkerAnimatedState extends State<BusMarkerAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _latAnim;
  late Animation<double> _lonAnim;

  LatLng _posAnterior = const LatLng(0, 0);
  LatLng _posActual   = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _posActual = LatLng(widget.bus.lat, widget.bus.lon);
  }

  @override
  void didUpdateWidget(BusMarkerAnimated old) {
    super.didUpdateWidget(old);
    final nueva = LatLng(widget.bus.lat, widget.bus.lon);
    if (nueva != _posActual) {
      _posAnterior = _posActual;
      _posActual   = nueva;
      _latAnim = Tween(begin: _posAnterior.latitude,  end: _posActual.latitude)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _lonAnim = Tween(begin: _posAnterior.longitude, end: _posActual.longitude)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        // Actualizar posición del marcador en el mapa
        // mediante callback o provider
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

**Nota:** La animación en flutter_map requiere reconstruir
el `MarkerLayer` con la posición interpolada. Usar
`AnimatedBuilder` + `setState` en `map_screen.dart`.

### Tarea 3 — Selector de ruta en contribución
```
Rama: feat/frontend-selector-ruta-contribucion
```
Cuando el usuario toca "Estoy en el bus", mostrar qué ruta
va a contribuir. Ahora que puede haber múltiples rutas,
el usuario debe confirmar en cuál va.

```dart
// Modificar subida_bus_sheet.dart:
// Agregar dropdown o lista de rutas disponibles
// antes de confirmar la subida

// Si solo hay una ruta (E598) → seleccionar automáticamente
// Si hay múltiples → mostrar lista para elegir
```

---

## 🗂️ Archivos Nuevos en v4

```
lib/
  services/
    websocket_service.dart      ← NUEVO
  widgets/
    bus_marker_animated.dart    ← NUEVO
```

---

## 📋 Orden de Implementación Recomendado

1. **WebSocket primero** — es el cambio más impactante y
   afecta la arquitectura del resto
2. **Animación después** — depende de tener datos fluidos del WebSocket
3. **Selector de ruta** — independiente, puede hacerse en paralelo

---

## 📋 Reglas de Trabajo
- **SIEMPRE** crear rama: `git checkout -b feat/frontend-nombre-tarea`
- **NUNCA** modificar `backend_bus_app/`
- Mantener polling HTTP como fallback del WebSocket
- Probar en Chrome Y dispositivo físico antes de PR

## ✅ Definition of Done
- [ ] App recibe actualizaciones de flota sin polling
- [ ] Indicador de conexión WebSocket visible en UI
- [ ] Marcadores se mueven suavemente entre posiciones
- [ ] Fallback a HTTP polling si WebSocket falla
- [ ] Compila en Chrome y dispositivo físico
- [ ] Commit: `feat(frontend): descripción corta`

---

## 🚀 Tareas Sprint v5A — Modo Conductor

### Pantalla de Login
```
Rama: feat/frontend-login-conductor
```
Pantalla inicial con dos opciones:
- "Soy Pasajero" → flujo actual (mapa/rutas)
- "Soy Conductor" → pedir PIN

```dart
// lib/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('San Antonio Bus Tracker', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
            child: const Text('Soy Pasajero'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _mostrarDialogoPin(context),
            child: const Text('Soy Conductor'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPin(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ingresa tu PIN'),
        content: TextField(
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'PIN de 4 dígitos'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => _verificarPin(context), child: const Text('Entrar')),
        ],
      ),
    );
  }
}
```

### UI Modo Conductor (minimalista)
```
Rama: feat/frontend-pantalla-conductor
```
Pantalla simplificada para conductor:
- GPS siempre activo
- Indicador de sesión activa
- "Dead Man's Switch" - botón que confirma que está vivo

```dart
// lib/screens/conductor_screen.dart
class ConductorScreen extends StatefulWidget {
  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  bool _activo = true;
  Timer? _deadManTimer;

  @override
  void initState() {
    super.initState();
    _iniciarGPSConductor();
    // Reiniciar Dead Man's Switch cada 25s
    _deadManTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      // Si no se presiona el botón, la sesión se closes
    });
  }

  @override
  void dispose() {
    _deadManTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de sesión
            Container(
              padding: const EdgeInsets.all(16),
              color: _activo ? Colors.green : Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_activo ? Icons.check_circle : Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _activo ? 'Sesión Activa' : 'Sesión Inactiva',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            // Botón Dead Man's Switch
            Expanded(
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(32),
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    // Reiniciar timer
                  },
                  child: const Text('MANTENER ACTIVO', style: TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Detección de Rol
```
Rama: feat/frontend-detectar-rol
```
- Si el login es de conductor → mostrar ConductorScreen
- Si es pasajero → mostrar HomeScreen (Mapa/Rutas)

```dart
// En main.dart
void main() async {
  final prefs = await SharedPreferences.getInstance();
  final modo = prefs.getString('modo'); // 'pasajero' o 'conductor'
  final tokenConductor = prefs.getString('token_conductor');

  runApp(BusApp(
    modo: modo == 'conductor' && tokenConductor != null ? Modo.conductor : Modo.pasajero,
  ));
}

enum Modo { pasajero, conductor }
```

### Definition of Done v5A
- [ ] Pantalla de login con opciones "Pasajero" / "Conductor"
- [ ] Dialog para ingreso de PIN de conductor
- [ ] API llama `/api/auth/conductor` y guarda token
- [ ] Conductor Screen muestra estado de sesión
- [ ] Botón "Mantener Activo" para Dead Man's Switch
- [ ] main.dart detecta rol y muestra pantalla correcta
- [ ] Compila en Chrome y dispositivo físico
- [ ] Commit: `feat(frontend): descripción corta`

---

## 🤖 Modelos y Skills Recomendados

### Modelo de IA (por complejidad de tarea)
| Tarea | Modelo Recomendado | Alternativa |
|-------|-------------------|------------|
| UI compleja, navegación, Dart avanzado | **GPT-4o** | GPT-4.1 |
| Tareas simples (UI tweaks, widgets) | **GPT-4o** | MiniMax M2.5 |
| Fallback (cuando se agoten créditos) | **MiniMax M2.5** | Siempre disponible |

**Recomendación:** Usa GPT-4o desde GitHub Copilot para tareas de Flutter/Dart (background GPS, autenticación, UI conductor). GPT-4o tiene mejor contexto del ecosistema Dart que otros modelos.

### Skills recomendadas
| Fase | Skill | Comando |
|------|-------|---------|
| v5A | `flutter-add-widget-test` | ✅ Ya instalada |
| v5A | `flutter-background-location` | `npx skills add <owner/repo@flutter-bg-location>` |
| v4 | `websocket-optimization` | `npx skills find websocket` |
| General | `flutter-development` | `npx skills add aj-geddes/useful-ai-prompts@flutter-development` |

---

## 🔀 Git Flow (OBLIGATORIO)

**Cada tarea debe seguir este flujo:**

1. **Crear rama desde master:**
   ```bash
   git checkout master
   git pull origin master
   git checkout -b feat/frontend-nombre-tarea
   # o fix/frontend-nombre-tarea
   # o chore/frontend-nombre-tarea
   ```

2. **Commit con convención:**
   ```
   feat(frontend): descripción corta
   fix(frontend): descripción corta
   chore(frontend): descripción corta
   ```

3. **Al terminar la tarea:**
   - Merge a master: `git checkout master && git merge nombre-rama`
   - Eliminar rama: `git branch -d nombre-rama`
   - Quedar en master

4. **Repositorio limpio:** Solo master y develop (sin ramas de feature activas)

**Excepciones:**
- Ramas de UI en desarrollo activo pueden ficar en develop temporarily
- Pero al completar, siempre merge a master

**NOhacer:**
- Commits directos a master (sin rama)
- Dejar ramas huérfanas sin merge
- Mezclar múltiples tareas en una misma rama
