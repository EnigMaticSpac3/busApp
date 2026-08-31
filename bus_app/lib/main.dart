// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/living_theme.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/conductor_login_screen.dart';
import 'screens/conductor_screen.dart';

void main() async {
  // Cargar variables desde .env (BACKEND_URL, etc.)
  await dotenv.load(fileName: '.env');
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LivingTheme(),
      child: MaterialApp(
        title: 'Transita',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/conductor-login': (context) => const ConductorLoginScreen(),
          '/conductor': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return ConductorScreen(
              conductorToken: args?['conductorToken'] ?? '',
              nombreConductor: args?['nombreConductor'] ?? '',
              rutaAsignada: args?['rutaAsignada'] ?? '',
            );
          },
        },
      ),
    );
  }
}
