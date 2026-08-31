import 'package:flutter/material.dart';

enum SearchAlignment { left, center, right }

class SettingsService extends ChangeNotifier {
  SearchAlignment _searchAlignment = SearchAlignment.center;
  SearchAlignment get searchAlignment => _searchAlignment;

  void setSearchAlignment(SearchAlignment value) {
    if (_searchAlignment == value) return;
    _searchAlignment = value;
    notifyListeners();
  }
}
