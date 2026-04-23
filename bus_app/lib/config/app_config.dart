// lib/config/app_config.dart
//
// Centraliza la URL del backend y otras constantes.
// Para cambiar entre desarrollo y producción, solo tocas este archivo.

class AppConfig {
  // En Chrome (web) localhost funciona porque el navegador corre en la misma máquina.
  // Cuando migremos a dispositivo físico Android/iOS, cambia esto por la IP
  // local de tu máquina (ej: 'http://192.168.1.X:8000').
  static const String backendUrl = 'http://192.168.0.5:8000';

  // Intervalo de polling a la flota en segundos
  static const int flotaPollingSegundos = 2;

  // Umbral mínimo de distancia (metros) para considerar que el bus llegó a una parada
  static const double umbraMetrosParada = 30.0;
}