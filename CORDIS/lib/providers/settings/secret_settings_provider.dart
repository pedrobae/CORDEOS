import 'package:flutter/material.dart';
import 'package:cordis/services/settings_service.dart';

class SecretSetProvider extends ChangeNotifier {
  bool _denseCipherCard = true;

  // Getters
  bool get denseCipherCard => _denseCipherCard;

  /// Initialize with stored settings
  Future<void> loadSettings() async {
    _denseCipherCard = SettingsService.getDenseCipherCard();
    notifyListeners();
  }

  void toggleDenseCipherCard() {
    _denseCipherCard = !_denseCipherCard;
    SettingsService.setDenseCipherCard(_denseCipherCard);
    notifyListeners();
  }
}
