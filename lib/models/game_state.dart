import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/ball_animation.dart';
import 'game_module.dart';
import 'game_config.dart';
import 'game_logic.dart';

/// 遊戲狀態類，只負責管理遊戲狀態
class GameState with ChangeNotifier {
  // 遊戲配置
  final GameConfig config;
  
  // 遊戲邏輯
  final GameLogic logic;
  
  // 遊戲模式
  GameMode _gameMode = GameMode.singleMatch;
  
  // 模塊列表
  List<GameModule> modules = [];
  
  // 單球模式的狀態
  int currentColumn = 0; // 從哪一欄開始
  double ballPositionX = 0;
  double ballPositionY = 0;
  int targetColumn = 0;
  
  // 多球模式的狀態
  List<int> startColumns = [];
  List<int> endColumns = [];
  List<double> ballPositionsX = [];
  List<double> ballPositionsY = [];
  
  // 遊戲狀態
  GameStatus status = GameStatus.ready;
  
  // Getter 方法
  GameMode get gameMode => _gameMode;
  
  // 設置遊戲模式
  set gameMode(GameMode mode) {
    _gameMode = mode;
    resetGame();
  }
  
  // 初始化遊戲
  GameState({
    GameConfig? config,
    GameLogic? logic,
  }) : 
    this.config = config ?? const GameConfig(),
    this.logic = logic ?? GameLogic(config: config ?? const GameConfig()) {
    // 初始化多球模式的陣列
    startColumns = List.filled(this.config.multiBallCount, 0);
    endColumns = List.filled(this.config.multiBallCount, 0);
    ballPositionsX = List.filled(this.config.multiBallCount, 0);
    ballPositionsY = List.filled(this.config.multiBallCount, 0);
    
    // 隨機設定起點和終點
    resetGame();
  }
  
  // 初始化單球模式的起點/終點與球座標
  void initMatch() {
    Map<String, int> points = logic.generateSingleBallPoints();
    currentColumn = points['startColumn']!;
    targetColumn = points['targetColumn']!;

    // 重置球的位置到起點（只保存列號，實際渲染時會轉換為像素）
    ballPositionX = currentColumn * 1.0;
    ballPositionY = config.rows * 1.0;
  }

  // 初始化多球模式的起點/終點與球座標
  void initMultiMatch() {
    Map<String, List<int>> points = logic.generateMultiBallPoints();
    startColumns = points['startColumns']!;
    endColumns = points['endColumns']!;

    for (int i = 0; i < config.multiBallCount; i++) {
      ballPositionsX[i] = startColumns[i] * 1.0;
      ballPositionsY[i] = config.rows * 1.0;
    }
  }
  
  // 重置遊戲
  void resetGame() {
    modules.clear();
    
    // 停止正在進行的動畫
    BallAnimation.stopAnimation();
    
    if (_gameMode == GameMode.singleMatch) {
      initMatch();
    } else {
      initMultiMatch();
    }
    
    status = GameStatus.ready;
    notifyListeners();
  }
  
  // 添加模塊
  bool addModule(GameModule module) {
    // 使用GameLogic檢查模塊是否在有效範圍內
    if (!logic.isModuleInValidRange(module)) {
      return false;
    }
    
    // 使用GameLogic檢查是否與現有模塊衝突
    if (logic.hasModuleConflict(module, modules)) {
      return false;
    }
    
    modules.add(module);
    notifyListeners();
    return true;
  }
  
  // 移除模塊
  void removeModule(Position position) {
    modules.removeWhere((module) => 
      module.position.row == position.row && 
      module.position.column <= position.column && 
      module.position.column + module.width > position.column
    );
    notifyListeners();
  }
  
  // 開始遊戲
  void startGame() {
    if (status == GameStatus.ready) {
      status = GameStatus.running;
      notifyListeners();
    }
  }
  
  // 使用動畫來模擬球的移動
  Future<void> simulateBallMovement({
    required TickerProvider vsync,
    required double cellSize,
  }) async {
    if (_gameMode == GameMode.singleMatch) {
      // 單球模式
      await BallAnimation.startAnimation(
        gameState: this,
        vsync: vsync,
        cellSize: cellSize,
        onComplete: () {
          // 動畫完成後的處理已在 BallAnimation 中實現
        },
      );
    } else {
      // 多球模式
      await BallAnimation.startMultiBallAnimation(
        gameState: this,
        vsync: vsync,
        cellSize: cellSize,
        onComplete: () {
          // 檢查所有球是否都到達正確的終點
          List<int> finalColumns = BallAnimation.getFinalColumns();
          bool allCorrect = logic.areAllBallsReachedCorrectTarget(finalColumns, endColumns);
          
          status = allCorrect ? GameStatus.success : GameStatus.failure;
          notifyListeners();
        },
      );
    }
  }
} 