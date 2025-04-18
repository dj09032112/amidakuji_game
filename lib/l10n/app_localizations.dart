import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app_zh.dart';
import 'app_en.dart';

/// 應用程式國際化類
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  // 支援的語言
  static const List<Locale> supportedLocales = [
    Locale('zh', 'TW'),
    Locale('en', 'US'),
  ];
  
  // 當前語言
  static Locale? _currentLocale;

  // 獲取當前語言
  static Locale get currentLocale => _currentLocale ?? supportedLocales.first;
  
  // 設置當前語言並更新UI
  static void setLocale(BuildContext context, Locale newLocale) {
    _currentLocale = newLocale;
    _AppLocalizationsState? state = _localizationsState[context.hashCode];
    state?.didChangeDependencies();
  }
  
  // 緩存語言實例
  static final Map<String, AppLocalizations> _cache = {};
  
  // 緩存 State 實例，用於刷新 UI
  static final Map<int, _AppLocalizationsState> _localizationsState = {};
  
  /// 從當前上下文中獲取本地化實例
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  /// 工廠構造函數，根據語言加載相應的本地化實例
  static AppLocalizations load(Locale locale) {
    final String languageTag = _getLanguageTag(locale);
    
    if (_cache.containsKey(languageTag)) {
      return _cache[languageTag]!;
    }
    
    // 根據語言加載相應的本地化實例
    AppLocalizations localizations;
    
    switch (locale.languageCode) {
      case 'en':
        localizations = AppLocalizationsEn(locale);
        break;
      case 'zh':
      default:
        localizations = AppLocalizationsZh(locale);
        break;
    }
    
    _cache[languageTag] = localizations;
    return localizations;
  }
  
  /// 獲取語言標籤
  static String _getLanguageTag(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  
  /// 注冊本地化代理
  static AppLocalizationsDelegate delegate = AppLocalizationsDelegate();
  
  // 以下是本地化翻譯的方法
  
  // 應用標題
  String get appTitle => '';
  
  // 遊戲功能文字
  String get resetGame => '';
  String get startGame => '';
  String get gameInProgress => '';
  String get newGame => '';
  
  // 遊戲模式
  String get gameMode => '';
  String get singleBallMode => '';
  String get multiBallMode => '';
  
  // 結果顯示
  String get singleBallSuccess => '';
  String get multiBallSuccess => '';
  String get singleBallFailure => '';
  String get multiBallFailure => '';
  
  // 工具相關
  String get toolboxTitle => '';
  String get horizontalModule => '';
  String get bridgeModule => '';
  
  // 遊戲提示
  String get singleBallHint => '';
  String get multiBallHint => '';
}

/// 本地化代理
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) {
    // 更新當前語言
    _currentLocale = locale;
    
    // 同步返回本地化實例
    return SynchronousFuture<AppLocalizations>(AppLocalizations.load(locale));
  }
  
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;

  // 存儲當前語言
  static Locale? _currentLocale;
}

/// 本地化構建器
class AppLocalizationsBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, AppLocalizations localization) builder;

  const AppLocalizationsBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  _AppLocalizationsState createState() => _AppLocalizationsState();
}

class _AppLocalizationsState extends State<AppLocalizationsBuilder> {
  @override
  void initState() {
    super.initState();
    // 註冊狀態實例
    AppLocalizations._localizationsState[context.hashCode] = this;
  }

  @override
  void dispose() {
    // 移除狀態實例
    AppLocalizations._localizationsState.remove(context.hashCode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, localizations);
  }
}