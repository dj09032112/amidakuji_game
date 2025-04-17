import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/game_board.dart';
import '../widgets/tool_panel.dart';

class GameScreen extends StatefulWidget {
  final double cellSize;

  const GameScreen({Key? key, this.cellSize = 50.0}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('爬梯子遊戲'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              gameState.resetGame();
            },
            tooltip: '重置遊戲',
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

  // 創建固定高度的結果顯示區域
  Widget _buildResultDisplay(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    
    String successText = gameState.gameMode == GameMode.singleMatch 
      ? '恭喜！小球成功到達終點！' 
      : '恭喜！所有小球都正確到達終點！';
    
    String failureText = gameState.gameMode == GameMode.singleMatch 
      ? '可惜！小球沒有到達指定終點！' 
      : '可惜！不是所有小球都到達正確終點！';
    
    // 固定高度的容器，即使沒有內容也保持空間
    return Container(
      height: 60, // 固定高度
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: gameState.status == GameStatus.success 
          ? Text(
              successText,
              key: const ValueKey('success'),
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            )
          : gameState.status == GameStatus.failure
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
    final gameState = Provider.of<GameState>(context);

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
              onPressed: gameState.status == GameStatus.ready
                  ? () {
                      gameState.startGame();
                      // 啟動小球動畫
                      gameState.simulateBallMovement(
                        vsync: this,
                        cellSize: widget.cellSize,
                      );
                    }
                  : gameState.status == GameStatus.success || gameState.status == GameStatus.failure
                      ? () {
                          gameState.resetGame();
                        }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: gameState.status == GameStatus.success
                    ? Colors.green
                    : gameState.status == GameStatus.failure
                        ? Colors.red
                        : Colors.blue,
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                gameState.status == GameStatus.ready
                    ? '開始'
                    : gameState.status == GameStatus.success || gameState.status == GameStatus.failure
                        ? '新遊戲'
                        : '進行中',
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
            gameState.gameMode == GameMode.singleMatch
              ? '提示：從工具箱中拖曳模塊到棋盤上，幫助小球從起點到達終點'
              : '提示：從工具箱中拖曳模塊到棋盤上，幫助所有小球從各自起點到達對應終點',
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
    final gameState = Provider.of<GameState>(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('遊戲模式：', style: TextStyle(fontWeight: FontWeight.bold)),
        SegmentedButton<GameMode>(
          segments: const [
            ButtonSegment<GameMode>(
              value: GameMode.singleMatch,
              label: Text('單球模式'),
              icon: Icon(Icons.looks_one),
            ),
            ButtonSegment<GameMode>(
              value: GameMode.multiMatch,
              label: Text('多球模式'),
              icon: Icon(Icons.filter_5),
            ),
          ],
          selected: {gameState.gameMode},
          onSelectionChanged: (Set<GameMode> selection) {
            if (selection.first != gameState.gameMode) {
              gameState.gameMode = selection.first;
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