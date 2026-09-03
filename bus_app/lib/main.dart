// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme/export.dart';
import 'theme/favorites_provider.dart';
import 'theme/notifications_provider.dart';
import 'theme/settings_service.dart';
import 'theme/offline_provider.dart';
import 'services/connectivity_service.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'services/crowdsourcing_service.dart';
import 'services/conductor_service.dart';
import 'services/auth_service.dart';
import 'services/alert_service.dart';
import 'services/route_cache_service.dart';
import 'providers/driver_credentials_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/driver_mode_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/conductor_login_screen.dart';
import 'screens/conductor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
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
  final AlertService _alertService = AlertService();
  final FavoritesProvider _favoritesProvider = FavoritesProvider();
  final NotificationsProvider _notificationsProvider = NotificationsProvider();
  final SettingsService _settingsService = SettingsService();
  final ConnectivityService _connectivityService = ConnectivityService();
  late final OfflineProvider _offlineProvider;
  final RouteCacheService _routeCacheService = RouteCacheService();
  late final DriverCredentialsProvider _driverCredentialsProvider;
  late final GamificationProvider _gamificationProvider;
  late final DriverModeProvider _driverModeProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateThemeFromTime();

    // Adapter providers (wrap existing services)
    _offlineProvider = OfflineProvider(_connectivityService);
    _driverCredentialsProvider = DriverCredentialsProvider(_authService);
    _gamificationProvider = GamificationProvider();
    _driverModeProvider = DriverModeProvider(_conductorService);

    // Initialize providers that load persisted state
    _connectivityService.init();
    _driverCredentialsProvider.init();
    _gamificationProvider.init();
    _routeCacheService.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsService.dispose();
    _crowdsourcingService.dispose();
    _conductorService.dispose();
    _alertService.dispose();
    _connectivityService.dispose();
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
        ChangeNotifierProvider<AlertService>.value(value: _alertService),
        // Offline-first route cache
        Provider<RouteCacheService>.value(value: _routeCacheService),
        // New providers
        ChangeNotifierProvider<FavoritesProvider>.value(value: _favoritesProvider),
        ChangeNotifierProvider<NotificationsProvider>.value(value: _notificationsProvider),
        ChangeNotifierProvider<SettingsService>.value(value: _settingsService),
        ChangeNotifierProvider<OfflineProvider>.value(value: _offlineProvider),
        // Driver mode adapter providers
        ChangeNotifierProvider<DriverCredentialsProvider>.value(value: _driverCredentialsProvider),
        ChangeNotifierProvider<GamificationProvider>.value(value: _gamificationProvider),
        ChangeNotifierProvider<DriverModeProvider>.value(value: _driverModeProvider),
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
              '/': (context) => const SplashScreen(),
              '/splash': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
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
