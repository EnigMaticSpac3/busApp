// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'theme/export.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/crowdsourcing_service.dart';
import 'services/conductor_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/conductor_login_screen.dart';
import 'screens/conductor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const BusApp());
}

class BusApp extends StatefulWidget {
  const BusApp({super.key});

  @override
  State<BusApp> createState() => _BusAppState();
}

class _BusAppState extends State<BusApp> with WidgetsBindingObserver {
  final LivingTheme _livingTheme = LivingTheme();
  final ApiService _apiService = ApiService();
  final WebSocketService _wsService = WebSocketService();
  final CrowdsourcingService _crowdsourcingService = CrowdsourcingService();
  final ConductorService _conductorService = ConductorService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateThemeFromTime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsService.dispose();
    _crowdsourcingService.dispose();
    _conductorService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateThemeFromTime();
    }
  }

  void _updateThemeFromTime() {
    _livingTheme.updateFromTime(TimeOfDay.now());
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme
        ChangeNotifierProvider<LivingTheme>.value(value: _livingTheme),
        // Services
        Provider<ApiService>.value(value: _apiService),
        Provider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<WebSocketService>.value(value: _wsService),
        ChangeNotifierProvider<CrowdsourcingService>.value(value: _crowdsourcingService),
        ChangeNotifierProvider<ConductorService>.value(value: _conductorService),
      ],
      child: ListenableBuilder(
        listenable: _livingTheme,
        builder: (context, _) {
          return MaterialApp(
            title: 'Transita',
            debugShowCheckedModeBanner: false,
            theme: _livingTheme.theme,
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
          );
        },
      ),
    );
  }
}
