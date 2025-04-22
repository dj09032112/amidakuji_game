import 'package:flutter/material.dart';

/// 語言提供者類，負責管理應用程式的語言狀態
class LocaleProvider with ChangeNotifier {
  /// 當前語言（預設為繁體中文 zh_TW）
  Locale _currentLocale = const Locale('zh', 'TW');

  /// 取得當前語言
  Locale get currentLocale => _currentLocale;

  /// 設定語言
  void setLocale(Locale newLocale) {
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      notifyListeners();
    }
  }
}
