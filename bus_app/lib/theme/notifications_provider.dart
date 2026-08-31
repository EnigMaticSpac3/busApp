import 'package:flutter/foundation.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime time;
  final String? routeCode;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    DateTime? time,
    this.routeCode,
    this.read = false,
  }) : time = time ?? DateTime.now();
}

class NotificationsProvider extends ChangeNotifier {
  final List<NotificationItem> _items = [];

  List<NotificationItem> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.read).length;

  void addNotification(NotificationItem item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void markAsRead(String id) {
    final item = _items.firstWhere((n) => n.id == id);
    if (!item.read) {
      item.read = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final item in _items) {
      item.read = true;
    }
    notifyListeners();
  }

  void mockDisruption(String routeCode) {
    addNotification(
      NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '⚠️ $routeCode — Desvío',
        body: 'Ruta desviada por Transistmica debido a obras. Tiempo estimado adicional: 10 min.',
        type: 'disruption',
        routeCode: routeCode,
      ),
    );
  }

  void mockArrivalAlert(String routeCode, String stop) {
    addNotification(
      NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '🚏 $routeCode — Próxima parada',
        body: 'Tu parada "$stop" está a 2 minutos. Prepárate para bajar.',
        type: 'arrival',
        routeCode: routeCode,
      ),
    );
  }

  // Seed mock notifications on first load
  void seedMock() {
    if (_items.isNotEmpty) return;
    addNotification(
      NotificationItem(
        id: 'mock_1',
        title: '🚌 K480 — En vivo',
        body: 'Bus K480 con destino a Bethania Expreso llegando en 3 min a Estación Albrook.',
        type: 'live',
        routeCode: 'K480',
      ),
    );
    addNotification(
      NotificationItem(
        id: 'mock_2',
        title: '⚠️ V500 — Retraso',
        body: 'Ruta V500 presenta retraso de 8 min por tráfico en Vía España.',
        type: 'disruption',
        routeCode: 'V500',
        read: true,
      ),
    );
  }
}
