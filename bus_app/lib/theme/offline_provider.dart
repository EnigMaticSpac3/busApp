import 'package:flutter/material.dart';

class OfflineProvider extends ChangeNotifier {
  bool _offline = false;
  bool get offline => _offline;

  void toggle() {
    _offline = !_offline;
    notifyListeners();
  }
}
