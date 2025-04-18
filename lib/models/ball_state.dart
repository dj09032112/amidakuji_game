import 'package:flutter/material.dart';
import 'dart:math';
import 'game_config.dart';
import 'game_logic.dart';
import 'game_module.dart';
import 'game_enums.dart';
import '../utils/ball_animation.dart';

/// 小球狀態類，負責管理小球的位置和移動
class BallState with ChangeNotifier {
  // 遊戲配置
  final GameConfig config;
  
  // 遊戲邏輯
  final GameLogic logic;
  
  // 遊戲模式
  GameMode _gameMode = GameMode.singleMatch;
  
  // 遊戲狀態
  GameStatus _status = GameStatus.ready;
  
  // 單球模式的狀態
  int _currentColumn = 0; // 從哪一欄開始
  double _ballPositionX = 0;
  double _ballPositionY = 0;
  int _targetColumn = 0;
  
  // 多球模式的狀態
  List<int> _startColumns = [];
  List<int> _endColumns = [];
  List<double> _ballPositionsX = [];
  List<double> _ballPositionsY = [];
  
  // Getter 方法
  GameMode get gameMode => _gameMode;
  GameStatus get status => _status;
  int get currentColumn => _currentColumn;
  double get ballPositionX => _ballPositionX;
  double get ballPositionY => _ballPositionY;
  int get targetColumn => _targetColumn;
  List<int> get startColumns => _startColumns;
  List<int> get endColumns => _endColumns;
  List<double> get ballPositionsX => _ballPositionsX;
  List<double> get ballPositionsY => _ballPositionsY;
  
  // 構造函數
  BallState({
    required this.config,
    required this.logic,
  }) {
    // 初始化多球模式的陣列
    _startColumns = List.filled(config.multiBallCount, 0);
    _endColumns = List.filled(config.multiBallCount, 0);
    _ballPositionsX = List.filled(config.multiBallCount, 0);
    _ballPositionsY = List.filled(config.multiBallCount, 0);
    
    // 隨機設定起點和終點
    resetBalls();
  }
  
  // 設置遊戲模式
  set gameMode(GameMode mode) {
    _gameMode = mode;
    resetBalls();
  }
  
  // 設置遊戲狀態
  set status(GameStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
  
  // 設置小球位置 (單球模式)
  set ballPositionX(double value) {
    _ballPositionX = value;
    notifyListeners();
  }
  
  set ballPositionY(double value) {
    _ballPositionY = value;
    notifyListeners();
  }
  
  // 設置多個小球的位置 (多球模式)
  void updateBallPosition(int index, double x, double y) {
    _ballPositionsX[index] = x;
    _ballPositionsY[index] = y;
    notifyListeners();
  }
  
  // 初始化單球模式的起點/終點與球座標
  void initMatch() {
    Map<String, int> points = logic.generateSingleBallPoints();
    _currentColumn = points['startColumn']!;
    _targetColumn = points['targetColumn']!;

    // 重置球的位置到起點（只保存列號，實際渲染時會轉換為像素）
    _ballPositionX = _currentColumn * 1.0;
    _ballPositionY = config.rows * 1.0;
  }

  // 初始化多球模式的起點/終點與球座標
  void initMultiMatch() {
    Map<String, List<int>> points = logic.generateMultiBallPoints();
    _startColumns = points['startColumns']!;
    _endColumns = points['endColumns']!;

    for (int i = 0; i < config.multiBallCount; i++) {
      _ballPositionsX[i] = _startColumns[i] * 1.0;
      _ballPositionsY[i] = config.rows * 1.0;
    }
  }
  
  // 重置小球
  void resetBalls() {
    // 停止正在進行的動畫
    BallAnimation.stopAnimation();
    
    if (_gameMode == GameMode.singleMatch) {
      initMatch();
    } else {
      initMultiMatch();
    }
    
    _status = GameStatus.ready;
    notifyListeners();
  }
  
  // 開始遊戲
  void startGame() {
    if (_status == GameStatus.ready) {
      _status = GameStatus.running;
      notifyListeners();
    }
  }
  
  // 使用動畫來模擬球的移動
  Future<void> simulateBallMovement({
    required TickerProvider vsync,
    required double cellSize,
    required List<GameModule> modules,
  }) async {
    if (_gameMode == GameMode.singleMatch) {
      // 單球模式
      await BallAnimation.startAnimation(
        ballState: this,
        modules: modules,
        logic: logic,
        vsync: vsync,
        cellSize: cellSize,
        onComplete: () {
          // 動畫完成後的處理
        },
      );
    } else {
      // 多球模式
      await BallAnimation.startMultiBallAnimation(
        ballState: this,
        modules: modules,
        logic: logic,
        vsync: vsync,
        cellSize: cellSize,
        onComplete: () {
          // 檢查所有球是否都到達正確的終點
          List<int> finalColumns = BallAnimation.getFinalColumns();
          bool allCorrect = logic.areAllBallsReachedCorrectTarget(finalColumns, _endColumns);
          
          _status = allCorrect ? GameStatus.success : GameStatus.failure;
          notifyListeners();
        },
      );
    }
  }
} 