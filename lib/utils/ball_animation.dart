import 'package:flutter/material.dart';
import '../models/game_module.dart';
import '../models/game_state.dart';

class BallAnimation {
  // 球的移動速度（單位：像素/秒）
  static const double ballSpeed = 150.0;
  
  // 動畫控制器
  static AnimationController? _controller;
  
  // 多球動畫控制器
  static List<AnimationController> _multiControllers = [];
  
  // 多球最終位置
  static List<int> _finalColumns = List.filled(5, 0);
  
  // 獲取最終列位置
  static List<int> getFinalColumns() {
    return _finalColumns;
  }
  
  // 啟動球的動畫 (單球模式)
  static Future<void> startAnimation({
    required GameState gameState,
    required TickerProvider vsync,
    required double cellSize,
    required Function onComplete,
  }) async {
    // 如果已經有動畫進行中，先停止
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _controller!.dispose();
    }
    
    // 計算動畫總時長（基於網格行數）
    final double totalDistance = gameState.rows * cellSize * 1.8; // 增加時間以包含轉彎移動
    final double estimatedDuration = totalDistance / ballSpeed;
    
    // 創建動畫控制器
    _controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (estimatedDuration * 1000).toInt()),
    );
    
    // 設置起始位置 - 只有在遊戲為ready或running狀態時才重置球位置
    if (gameState.status == GameStatus.ready || gameState.status == GameStatus.running) {
      gameState.ballPositionX = gameState.currentColumn * cellSize + cellSize / 2 - (cellSize * 0.6 / 2);
      gameState.ballPositionY = gameState.rows * cellSize - cellSize / 2 - (cellSize * 0.6 / 2);
    }
    
    // 模擬球的移動路徑，包括轉彎點
    List<PathPoint> pathPoints = _calculateDetailedPath(gameState, cellSize);
    
    // 建立關鍵幀
    List<TweenSequenceItem<Offset>> tweenItems = [];
    
    Offset currentPosition = Offset(gameState.ballPositionX, gameState.ballPositionY);
    
    for (int i = 0; i < pathPoints.length; i++) {
      final point = pathPoints[i];
      final x = point.x;
      final y = point.y;
      final targetPosition = Offset(x, y);
      
      // 增加轉彎點的動畫權重，讓轉彎看起來更自然
      double weight = point.isTurningPoint ? 1.5 : 1.0;
      
      tweenItems.add(
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: currentPosition,
            end: targetPosition,
          ),
          weight: weight,
        ),
      );
      
      // 更新當前位置為下一段動畫的起點
      currentPosition = targetPosition;
    }
    
    // 創建動畫序列
    final Animation<Offset> animation = TweenSequence<Offset>(tweenItems).animate(_controller!);
    
    // 監聽動畫更新
    animation.addListener(() {
      gameState.ballPositionX = animation.value.dx;
      gameState.ballPositionY = animation.value.dy;
      gameState.notifyListeners();
    });
    
    // 動畫完成時的處理
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 判斷結果
        final lastPoint = pathPoints.last;
        final lastColumn = (lastPoint.x - (cellSize * 0.6 / 2) + cellSize / 2) ~/ cellSize;
        
        // 球已到達終點，設置狀態並通知監聽器
        if (lastColumn == gameState.targetColumn) {
          gameState.status = GameStatus.success;
        } else {
          gameState.status = GameStatus.failure;
        }
        gameState.notifyListeners();
        
        // 回調通知動畫完成，但不要重置球位置
        onComplete();
      }
    });
    
    // 開始動畫
    _controller!.forward();
  }
  
  // 啟動多球動畫 (多球模式)
  static Future<void> startMultiBallAnimation({
    required GameState gameState,
    required TickerProvider vsync,
    required double cellSize,
    required Function onComplete,
  }) async {
    // 如果已經有動畫進行中，先停止所有動畫
    stopAnimation();
    
    // 清空動畫控制器列表
    _multiControllers = [];
    
    // 計算動畫總時長（基於網格行數）
    final double totalDistance = gameState.rows * cellSize * 1.8; // 增加時間以包含轉彎移動
    final double estimatedDuration = totalDistance / ballSpeed;
    
    // 標記完成的動畫數量
    int completedAnimations = 0;
    
    // 為每個球建立動畫
    for (int ballIndex = 0; ballIndex < 5; ballIndex++) {
      // 建立動畫控制器
      final controller = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: (estimatedDuration * 1000).toInt()),
      );
      
      _multiControllers.add(controller);
      
      // 設置起始位置 - 只有在遊戲為ready或running狀態時才重置球位置
      final startColumn = gameState.startColumns[ballIndex];
      if (gameState.status == GameStatus.ready || gameState.status == GameStatus.running) {
        gameState.ballPositionsX[ballIndex] = startColumn * cellSize + cellSize / 2 - (cellSize * 0.6 / 2);
        gameState.ballPositionsY[ballIndex] = gameState.rows * cellSize - cellSize / 2 - (cellSize * 0.6 / 2);
      }
      
      // 計算詳細路徑
      List<PathPoint> pathPoints = _calculateDetailedPath(
        gameState, 
        cellSize, 
        startColumn
      );
      
      // 建立關鍵幀序列
      List<TweenSequenceItem<Offset>> tweenItems = [];
      
      Offset currentPosition = Offset(
        gameState.ballPositionsX[ballIndex], 
        gameState.ballPositionsY[ballIndex]
      );
      
      for (int i = 0; i < pathPoints.length; i++) {
        final point = pathPoints[i];
        final targetPosition = Offset(point.x, point.y);
        
        // 增加轉彎點的動畫權重，讓轉彎看起來更自然
        double weight = point.isTurningPoint ? 1.5 : 1.0;
        
        tweenItems.add(
          TweenSequenceItem<Offset>(
            tween: Tween<Offset>(
              begin: currentPosition,
              end: targetPosition,
            ),
            weight: weight,
          ),
        );
        
        // 更新當前位置為下一段動畫的起點
        currentPosition = targetPosition;
      }
      
      // 創建動畫序列
      final animation = TweenSequence<Offset>(tweenItems).animate(controller);
      
      // 監聽動畫更新
      animation.addListener(() {
        gameState.ballPositionsX[ballIndex] = animation.value.dx;
        gameState.ballPositionsY[ballIndex] = animation.value.dy;
        gameState.notifyListeners();
      });
      
      // 動畫完成時的處理
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // 記錄最終位置
          final lastPoint = pathPoints.last;
          final lastColumn = (lastPoint.x - (cellSize * 0.6 / 2) + cellSize / 2) ~/ cellSize;
          _finalColumns[ballIndex] = lastColumn;
          
          // 增加已完成的動畫計數
          completedAnimations++;
          
          // 當所有動畫都完成時，檢查結果並設置狀態，然後調用回調
          if (completedAnimations >= 5) {
            onComplete();
          }
        }
      });
      
      // 開始動畫
      controller.forward();
    }
  }
  
  // 計算球的詳細移動路徑，包括轉彎中間點
  static List<PathPoint> _calculateDetailedPath(
    GameState gameState, 
    double cellSize, 
    [int? startCol]
  ) {
    List<PathPoint> detailedPath = [];
    int col = startCol ?? gameState.currentColumn;
    
    // 計算球的初始位置（網格中心點）
    double ballCenterX(int column) => column * cellSize + cellSize / 2 - (cellSize * 0.6 / 2);
    double ballCenterY(int row) => row * cellSize + cellSize / 2 - (cellSize * 0.6 / 2);
    
    // 從底部向上移動
    for (int row = gameState.rows - 1; row >= 0; row--) {
      bool hasTurned = false;
      
      // 檢查當前行是否有模塊
      for (var module in gameState.modules.where((m) => m.position.row == row)) {
        if (module.type == ModuleType.horizontal) {
          if (module.position.column == col) {
            // 如果模塊起點與當前列相同，往右移
            
            // 先到達模塊所在行的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col), 
              ballCenterY(row), 
              false
            ));
            
            // 然後水平向右移動到下一列的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col + 1), 
              ballCenterY(row), 
              true
            ));
            
            col++;
            hasTurned = true;
            break;
          } else if (module.position.column + 1 == col) {
            // 如果模塊終點與當前列相同，往左移
            
            // 先到達模塊所在行的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col), 
              ballCenterY(row), 
              false
            ));
            
            // 然後水平向左移動到下一列的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col - 1), 
              ballCenterY(row), 
              true
            ));
            
            col--;
            hasTurned = true;
            break;
          }
        } else if (module.type == ModuleType.bridge) {
          if (module.position.column == col) {
            // 如果橋的起點與當前列相同，跳過中間一列
            
            // 先到達模塊所在行的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col), 
              ballCenterY(row), 
              false
            ));
            
            // 然後水平向右移動跨越中間列，到達橋的終點中心點
            detailedPath.add(PathPoint(
              ballCenterX(col + 2), 
              ballCenterY(row), 
              true
            ));
            
            col += 2;
            hasTurned = true;
            break;
          } else if (module.position.column + 2 == col) {
            // 如果橋的終點與當前列相同，跳過中間一列
            
            // 先到達模塊所在行的中心點
            detailedPath.add(PathPoint(
              ballCenterX(col), 
              ballCenterY(row), 
              false
            ));
            
            // 然後水平向左移動跨越中間列，到達橋的起點中心點
            detailedPath.add(PathPoint(
              ballCenterX(col - 2), 
              ballCenterY(row), 
              true
            ));
            
            col -= 2;
            hasTurned = true;
            break;
          }
        }
      }
      
      // 如果沒有轉彎，添加正常向上移動的路徑點
      if (!hasTurned) {
        detailedPath.add(PathPoint(
          ballCenterX(col), 
          ballCenterY(row), 
          false
        ));
      }
    }
    
    return detailedPath;
  }
  
  // 停止動畫
  static void stopAnimation() {
    // 停止單球動畫
    if (_controller != null) {
      if (_controller!.isAnimating) {
        _controller!.stop();
      }
      _controller!.dispose();
      _controller = null;
    }
    
    // 停止多球動畫
    for (var controller in _multiControllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.dispose();
    }
    _multiControllers.clear();
  }
}

// 表示路徑上的一個點，含有精確的像素坐標
class PathPoint {
  final double x;
  final double y;
  final bool isTurningPoint;
  
  PathPoint(this.x, this.y, this.isTurningPoint);
} 