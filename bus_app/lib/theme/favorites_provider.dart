import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteRoutes = {};
  final Set<String> _favoriteStops = {};

  Set<String> get favoriteRoutes => Set.unmodifiable(_favoriteRoutes);
  Set<String> get favoriteStops => Set.unmodifiable(_favoriteStops);

  bool isRouteFavorite(String code) => _favoriteRoutes.contains(code);
  bool isStopFavorite(String name) => _favoriteStops.contains(name);

  void toggleRoute(String code) {
    if (_favoriteRoutes.contains(code)) {
      _favoriteRoutes.remove(code);
    } else {
      _favoriteRoutes.add(code);
    }
    notifyListeners();
  }

  void toggleStop(String name) {
    if (_favoriteStops.contains(name)) {
      _favoriteStops.remove(name);
    } else {
      _favoriteStops.add(name);
    }
    notifyListeners();
  }
}
