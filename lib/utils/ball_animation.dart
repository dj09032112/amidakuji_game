import 'package:flutter/material.dart';
import '../models/game_module.dart';
import '../models/ball_state.dart';
import '../models/game_logic.dart';
import '../models/game_enums.dart';
import 'grid_mapper.dart';

class BallAnimation {
  // 動畫控制器
  static AnimationController? _controller;
  
  // 多球動畫控制器
  static List<AnimationController> _multiControllers = [];
  
  // 多球最終位置
  static List<int> _finalColumns = [];
  
  // 獲取最終列位置
  static List<int> getFinalColumns() {
    return _finalColumns;
  }

  // 計算動畫時長
  static double _calculateAnimationDuration(BallState ballState, double cellSize) {
    final double totalDistance = ballState.config.rows * cellSize * 1.5;
    return totalDistance / ballState.config.ballSpeed;
  }

  // 創建動畫序列
  static List<TweenSequenceItem<Offset>> _createTweenSequence(
    List<PathPoint> pathPoints,
    Offset startPosition,
  ) {
    List<TweenSequenceItem<Offset>> tweenItems = [];
    Offset currentPosition = startPosition;

    for (final point in pathPoints) {
      final targetPosition = Offset(point.x, point.y);
      tweenItems.add(
        TweenSequenceItem<Offset>(
          tween: Tween<Offset>(
            begin: currentPosition,
            end: targetPosition,
          ),
          weight: point.isTurningPoint ? 1.5 : 1.0,
        ),
      );
      currentPosition = targetPosition;
    }

    return tweenItems;
  }
  
  // 啟動球的動畫 (單球模式)
  static Future<void> startAnimation({
    required BallState ballState,
    required List<GameModule> modules,
    required GameLogic logic,
    required TickerProvider vsync,
    required double cellSize,
    required Function onComplete,
  }) async {
    // 如果已經有動畫進行中，先停止
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _controller!.dispose();
    }
    
    final gridMapper = GridMapper(
      cellSize: cellSize,
      rows: ballState.config.rows,
      columns: ballState.config.columns,
    );
    
    final estimatedDuration = _calculateAnimationDuration(ballState, cellSize);
    
    // 創建動畫控制器
    _controller = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (estimatedDuration * 1000).toInt()),
    );
    
    // 設置起始位置
    if (ballState.status == GameStatus.ready || ballState.status == GameStatus.running) {
      final startPosition = gridMapper.calculateBallStartPosition(ballState.currentColumn);
      ballState.ballPositionX = startPosition.dx;
      ballState.ballPositionY = startPosition.dy;
    }
    
    // 計算路徑
    final pathPoints = logic.calculateBallPath(
      modules: modules,
      startColumn: ballState.currentColumn,
      cellSize: cellSize,
    );
    
    // 創建動畫序列
    final tweenItems = _createTweenSequence(
      pathPoints,
      Offset(ballState.ballPositionX, ballState.ballPositionY),
    );
    
    final animation = TweenSequence<Offset>(tweenItems).animate(_controller!);
    
    // 監聽動畫更新
    animation.addListener(() {
      ballState.ballPositionX = animation.value.dx;
      ballState.ballPositionY = animation.value.dy;
    });
    
    // 動畫完成時的處理
    _controller!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final lastColumn = logic.calculateFinalColumn(pathPoints, cellSize);
        ballState.status = lastColumn == ballState.targetColumn
          ? GameStatus.success
          : GameStatus.failure;
        onComplete();
      }
    });
    
    _controller!.forward();
  }
  
  // 啟動多球動畫 (多球模式)
  static Future<void> startMultiBallAnimation({
    required BallState ballState,
    required List<GameModule> modules,
    required GameLogic logic,
    required TickerProvider vsync,
    required double cellSize,
    required Function onComplete,
  }) async {
    stopAnimation();
    
    final gridMapper = GridMapper(
      cellSize: cellSize,
      rows: ballState.config.rows,
      columns: ballState.config.columns,
    );
    
    _multiControllers = [];
    _finalColumns = List.filled(ballState.config.multiBallCount, 0);
    
    final estimatedDuration = _calculateAnimationDuration(ballState, cellSize);
    int completedAnimations = 0;
    
    for (int ballIndex = 0; ballIndex < ballState.config.multiBallCount; ballIndex++) {
      final controller = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: (estimatedDuration * 1000).toInt()),
      );
      
      _multiControllers.add(controller);
      
      if (ballState.status == GameStatus.ready || ballState.status == GameStatus.running) {
        final startPosition = gridMapper.calculateBallStartPosition(ballState.startColumns[ballIndex]);
        ballState.updateBallPosition(ballIndex, startPosition.dx, startPosition.dy);
      }
      
      final pathPoints = logic.calculateBallPath(
        modules: modules,
        startColumn: ballState.startColumns[ballIndex],
        cellSize: cellSize,
      );
      
      final tweenItems = _createTweenSequence(
        pathPoints,
        Offset(ballState.ballPositionsX[ballIndex], ballState.ballPositionsY[ballIndex]),
      );
      
      final animation = TweenSequence<Offset>(tweenItems).animate(controller);
      
      final currentBallIndex = ballIndex; // 捕獲當前球的索引
      animation.addListener(() {
        ballState.updateBallPosition(
          currentBallIndex,
          animation.value.dx,
          animation.value.dy
        );
      });
      
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finalColumns[currentBallIndex] = logic.calculateFinalColumn(pathPoints, cellSize);
          if (++completedAnimations >= ballState.config.multiBallCount) {
            onComplete();
          }
        }
      });
      
      controller.forward();
    }
  }
  
  // 停止動畫
  static void stopAnimation() {
    if (_controller != null) {
      if (_controller!.isAnimating) {
        _controller!.stop();
      }
      _controller!.dispose();
      _controller = null;
    }
    
    for (var controller in _multiControllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.dispose();
    }
    _multiControllers.clear();
  }
} 