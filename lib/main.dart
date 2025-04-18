import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/game_config.dart';
import 'models/game_logic.dart';
import 'models/board_state.dart';
import 'models/ball_state.dart';
import 'models/game_controller.dart';
import 'screens/game_screen.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 建立遊戲配置
    final gameConfig = const GameConfig();
    // 建立遊戲邏輯
    final gameLogic = GameLogic(config: gameConfig);
    // 建立遊戲控制器
    final gameController = GameController(
      config: gameConfig,
      logic: gameLogic,
    );
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BoardState>.value(value: gameController.boardState),
        ChangeNotifierProvider<BallState>.value(value: gameController.ballState),
        Provider<GameController>.value(value: gameController),
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: '爬梯子遊戲',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            // 配置本地化
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                // 確保 AppLocalizations 已經加載
                final AppLocalizations? localizations = AppLocalizations.of(context);
                
                return const GameScreen();
              }
            ),
            debugShowCheckedModeBanner: false,
          );
        }
      ),
    );
  }
} 