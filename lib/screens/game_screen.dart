import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board_state.dart';
import '../models/ball_state.dart';
import '../models/game_controller.dart';
import '../models/game_enums.dart';
import '../widgets/game_board.dart';
import '../widgets/tool_panel.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';

class GameScreen extends StatefulWidget {
  final double cellSize;

  const GameScreen({
    Key? key, 
    this.cellSize = 50.0, 
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final ballState = Provider.of<BallState>(context);
    final gameController = Provider.of<GameController>(context, listen: false);
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.appTitle),
        actions: [
          // 語言切換下拉選單
          _buildLanguageDropdown(context),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              gameController.resetGame();
            },
            tooltip: localizations.resetGame,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // 固定高度的結果顯示區域
                  _buildResultDisplay(context),
                  // 遊戲內容（棋盤）
                  Center(
                    child: _buildGameContent(context),
                  ),
                  // 控制面板（工具箱和按鈕）
                  _buildControlPanel(context),
                  // 底部間距，防止內容被遮擋
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 創建語言切換下拉選單
  Widget _buildLanguageDropdown(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: DropdownButton<Locale>(
        value: currentLocale,
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            localeProvider.setLocale(context, newLocale);
          }
        },
        items: AppLocalizations.supportedLocales.map((Locale locale) {
          String languageText = '';
          if (locale.languageCode == 'zh') {
            languageText = '中文';
          } else if (locale.languageCode == 'en') {
            languageText = 'English';
          }
          
          return DropdownMenuItem<Locale>(
            value: locale,
            child: Text(languageText),
          );
        }).toList(),
        underline: Container(), // 隱藏下劃線
        icon: const Icon(Icons.language, color: Colors.white),
      ),
    );
  }

  // 創建固定高度的結果顯示區域
  Widget _buildResultDisplay(BuildContext context) {
    final ballState = Provider.of<BallState>(context);
    final localizations = AppLocalizations.of(context)!;
    
    String successText = ballState.gameMode == GameMode.singleMatch 
      ? localizations.singleBallSuccess 
      : localizations.multiBallSuccess;
    
    String failureText = ballState.gameMode == GameMode.singleMatch 
      ? localizations.singleBallFailure 
      : localizations.multiBallFailure;
    
    // 固定高度的容器，即使沒有內容也保持空間
    return Container(
      height: 60, // 固定高度
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ballState.status == GameStatus.success 
          ? Text(
              successText,
              key: const ValueKey('success'),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            )
          : ballState.status == GameStatus.failure
            ? Text(
                failureText,
                key: const ValueKey('failure'),
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')), // 空佔位
      ),
    );
  }

  Widget _buildGameContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 遊戲棋盤
        GameBoard(cellSize: widget.cellSize),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    final ballState = Provider.of<BallState>(context);
    final boardState = Provider.of<BoardState>(context, listen: false);
    final gameController = Provider.of<GameController>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
      color: Colors.grey.shade100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 遊戲模式選擇
          _buildGameModeSelector(context),
          const SizedBox(height: 10.0),
          
          // 工具面板
          ToolPanel(cellSize: widget.cellSize),
          const SizedBox(height: 10.0),
          // 開始按鈕
          SizedBox(
            width: 200.0,
            height: 45.0,
            child: ElevatedButton(
              onPressed: ballState.status == GameStatus.ready
                  ? () {
                      gameController.startGame(this, widget.cellSize);
                    }
                  : ballState.status == GameStatus.success || ballState.status == GameStatus.failure
                      ? () {
                          gameController.resetGame();
                        }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ballState.status == GameStatus.success
                    ? Colors.green
                    : ballState.status == GameStatus.failure
                        ? Colors.red
                        : Colors.blue,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                ballState.status == GameStatus.ready
                    ? localizations.startGame
                    : ballState.status == GameStatus.success || ballState.status == GameStatus.failure
                        ? localizations.newGame
                        : localizations.gameInProgress,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6.0),
          // 遊戲說明
          Text(
            ballState.gameMode == GameMode.singleMatch
              ? localizations.singleBallHint
              : localizations.multiBallHint,
            style: const TextStyle(
              fontSize: 11.0,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 遊戲模式選擇器
  Widget _buildGameModeSelector(BuildContext context) {
    final ballState = Provider.of<BallState>(context);
    final gameController = Provider.of<GameController>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(localizations.gameMode, style: const TextStyle(fontWeight: FontWeight.bold)),
        SegmentedButton<GameMode>(
          segments: [
            ButtonSegment<GameMode>(
              value: GameMode.singleMatch,
              label: Text(localizations.singleBallMode),
              icon: const Icon(Icons.looks_one),
            ),
            ButtonSegment<GameMode>(
              value: GameMode.multiMatch,
              label: Text(localizations.multiBallMode),
              icon: const Icon(Icons.filter_5),
            ),
          ],
          selected: {ballState.gameMode},
          onSelectionChanged: (Set<GameMode> selection) {
            if (selection.first != ballState.gameMode) {
              gameController.setGameMode(selection.first);
            }
          },
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    // 確保在畫面銷毀時停止動畫
    super.dispose();
  }
} 