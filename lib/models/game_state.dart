import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/ball_animation.dart';
import 'game_module.dart';

enum GameStatus {
  ready, // 遊戲尚未開始
  running, // 遊戲進行中
  success, // 成功到達終點
  failure, // 未到達指定終點
}

// 遊戲模式枚舉
enum GameMode {
  singleMatch, // 單起點對應單終點
  multiMatch,  // 多起點對應多終點
}

class GameState with ChangeNotifier {
  // 網格尺寸
  final int columns = 5;
  final int rows = 8;
  
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
  List<int> startColumns = List.filled(5, 0);
  List<int> endColumns = List.filled(5, 0);
  List<double> ballPositionsX = List.filled(5, 0);
  List<double> ballPositionsY = List.filled(5, 0);
  
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
  GameState() {
    // 隨機設定起點和終點
    resetGame();
  }
  
  // 重置遊戲
  void resetGame() {
    modules.clear();
    
    // 停止正在進行的動畫
    BallAnimation.stopAnimation();
    
    if (_gameMode == GameMode.singleMatch) {
      // 單球模式 - 隨機選擇起點和終點
      Random random = Random();
      currentColumn = random.nextInt(columns);
      targetColumn = random.nextInt(columns);
      
      // 重置球的位置到起點
      ballPositionX = currentColumn * 1.0; // 這裡只保存列號，實際渲染時會計算像素
      ballPositionY = rows * 1.0; // 同上
    } else {
      // 多球模式 - 為每個起點隨機指定終點
      Random random = Random();
      
      // 生成 0-4 的隨機排列作為終點順序
      List<int> targetOrder = List.generate(5, (index) => index);
      targetOrder.shuffle(random);
      
      // 設置起點和終點
      for (int i = 0; i < 5; i++) {
        startColumns[i] = i;        // 起點固定為 0,1,2,3,4
        endColumns[i] = targetOrder[i]; // 終點為打亂後的順序
        
        // 重置球的位置到起點
        ballPositionsX[i] = i * 1.0; // 這裡只保存列號，實際渲染時會計算像素
        ballPositionsY[i] = rows * 1.0; // 同上
      }
    }
    
    status = GameStatus.ready;
    notifyListeners();
  }
  
  // 添加模塊
  bool addModule(GameModule module) {
    // 檢查模塊是否在有效範圍內
    if (module.position.row < 0 || 
        module.position.row >= rows || 
        module.position.column < 0 || 
        module.position.column + module.width - 1 >= columns) {
      return false;
    }
    
    // 檢查是否與現有模塊衝突
    for (var existingModule in modules) {
      if (module.intersectsWith(existingModule)) {
        return false;
      }
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
          bool allCorrect = true;
          List<int> finalColumns = BallAnimation.getFinalColumns();
          
          for (int i = 0; i < 5; i++) {
            if (finalColumns[i] != endColumns[i]) {
              allCorrect = false;
              break;
            }
          }
          
          status = allCorrect ? GameStatus.success : GameStatus.failure;
          notifyListeners();
        },
      );
    }
  }
} 