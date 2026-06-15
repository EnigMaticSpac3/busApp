// lib/config/app_config.dart
//
// Centraliza la URL del backend y otras constantes.
// BACKEND_URL se lee desde el archivo .env (ver .env.example).
// Si no está disponible, se usa un valor por defecto como fallback.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// URL del backend. Se lee desde la variable BACKEND_URL en .env.
  /// Si el archivo .env no está cargado o la variable no existe,
  /// se usa el valor por defecto.
  static String get backendUrl {
    if (dotenv.isInitialized && dotenv.env.containsKey('BACKEND_URL')) {
      return dotenv.env['BACKEND_URL']!;
    }
    return 'https://library-doodle-keenly.ngrok-free.dev';
  }

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
  static const Color colorPrimary50 = Color(0xFFe8f2fa);
  static const Color colorPrimary300 = Color(0xFF7ab3e0);
  static const Color colorPrimary600 = Color(0xFF2f74ad);
  static const Color colorPrimary900 = Color(0xFF013a70);

  // Secundario - Rich Cerulean (#2f74ad)
  static const Color colorSecondary = Color(0xFF2f74ad);

  // Acento/ETA normal - Lemon Lime (#bfd244)
  static const Color colorAccent = Color(0xFFbfd244);
  static const Color colorAccent50 = Color(0xFFf4f8d0);
  static const Color colorAccent300 = Color(0xFFd4e46a);
  static const Color colorAccent600 = Color(0xFF8fa020);
  static const Color colorAccent900 = Color(0xFF576010);

  // Alerta/Urgencia - Atomic Tangerine (#e57a44)
  static const Color colorAlert = Color(0xFFe57a44);
  static const Color colorAlert50 = Color(0xFFfdf0e8);
  static const Color colorAlert300 = Color(0xFFf0ac80);
  static const Color colorAlert600 = Color(0xFFb85520);
  static const Color colorAlert900 = Color(0xFF7a2f0e);

  // Texto principal - Carbon Black (#242423)
  static const Color colorText = Color(0xFF242423);
  static const Color colorText50 = Color(0xFFf0f0ef);
  static const Color colorText300 = Color(0xFF868684);
  static const Color colorText600 = Color(0xFF484846);
  static const Color colorText900 = Color(0xFF101010);

  // Superficies
  static const Color surfacePrimary = Color(0xFFffffff);
  static const Color surfaceSecondary = Color(0xFFf2f2f0);
  static const Color surfaceInfo = Color(0xFFe8f2fa);
  static const Color surfaceSuccess = Color(0xFFf4f8d0);
  static const Color surfaceWarning = Color(0xFFfdf0e8);

  // Texto sobre colores
  static const Color textOnPrimary = Color(0xFFffffff);
  static const Color textOnLime = Color(0xFF2a3800);
  static const Color textOnOrange = Color(0xFF4a1a00);
  static const Color textNeutral = Color(0xFF242423);
}
