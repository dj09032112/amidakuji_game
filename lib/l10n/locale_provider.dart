import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// 語言提供者類，負責管理應用程序的語言狀態
class LocaleProvider with ChangeNotifier {
  // 當前語言
  Locale _locale;

  // 構造函數
  LocaleProvider({Locale? locale}) : _locale = locale ?? AppLocalizations.supportedLocales.first;

  // 獲取當前語言
  Locale get locale => _locale;

  // 設置語言
  void setLocale(BuildContext context, Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      AppLocalizations.setLocale(context, newLocale);
      notifyListeners();
    }
  }
} 