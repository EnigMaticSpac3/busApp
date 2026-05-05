// lib/config/app_config.dart
//
// Centraliza la URL del backend y otras constantes.
// Para cambiar entre desarrollo y producción, solo tocas este archivo.

import 'package:flutter/material.dart';

class AppConfig {
  // En Chrome (web) localhost funciona porque el navegador corre en la misma máquina.
  // Cuando migremos a dispositivo físico Android/iOS, cambia esto por la IP
  // local de tu máquina (ej: 'http://192.168.1.X:8000').
  // static const String backendUrl = 'http://192.168.0.5:8000';
  static const String backendUrl = 'https://library-doodle-keenly.ngrok-free.dev';

  // Intervalo de polling a la flota en segundos
  static const int flotaPollingSegundos = 2;

  // Umbral mínimo de distancia (metros) para considerar que el bus llegó a una parada
  static const double umbraMetrosParada = 30.0;

  // ⚠️ Modo debug: bypasea el map matching en el backend para pruebas en casa.
  // Cambia a false antes de hacer el commit final / producción.
  static const bool debugCrowdsourcing = false;

  // === Paleta de Colores Profesional ===
  // Basada en spec: Baltic Blue, Rich Cerulean, Lemon Lime, Atomic Tangerine, Carbon Black

  // Primario - Baltic Blue (#0256a4)
  static const Color colorPrimary = Color(0xFF0256a4);

  // Secundario - Rich Cerulean (#2f74ad)
  static const Color colorSecondary = Color(0xFF2f74ad);

  // Acento/ETA normal - Lemon Lime (#bfd244)
  static const Color colorAccent = Color(0xFFbfd244);

  // Alerta/Urgencia - Atomic Tangerine (#e57a44)
  static const Color colorAlert = Color(0xFFe57a44);

  // Texto principal - Carbon Black (#242423)
  static const Color colorText = Color(0xFF242423);

  // Superficies
  static const Color surfacePrimary = Color(0xFFffffff);
  static const Color surfaceSecondary = Color(0xFFf2f2f0);
  static const Color surfaceInfo = Color(0xFFe8f2fa);
  static const Color surfaceSuccess = Color(0xFFf4f8d0);
  static const Color surfaceWarning = Color(0xFFfdf0e8);

  // Variantes para estados
  static const Color primaryLight = Color(0xFF7ab3e0);
  static const Color primaryDark = Color(0xFF013a70);
  static const Color accentDark = Color(0xFF8fa020);
  static const Color alertDark = Color(0xFFb85520);
  static const Color textSecondary = Color(0xFF484846);
  static const Color borderLight = Color(0xFF868684);
}
