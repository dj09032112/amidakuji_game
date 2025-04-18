import 'package:flutter/material.dart';
import 'game_config.dart';
import 'game_logic.dart';
import 'board_state.dart';
import 'ball_state.dart';
import 'game_enums.dart';

/// 遊戲控制器，負責協調 BoardState 和 BallState
class GameController {
  // 遊戲配置
  final GameConfig config;
  
  // 遊戲邏輯
  final GameLogic logic;
  
  // 棋盤狀態
  final BoardState boardState;
  
  // 小球狀態
  final BallState ballState;
  
  // 構造函數
  GameController({
    GameConfig? config,
    GameLogic? logic,
  }) : 
    this.config = config ?? const GameConfig(),
    this.logic = logic ?? GameLogic(config: config ?? const GameConfig()),
    boardState = BoardState(
      config: config ?? const GameConfig(),
      logic: logic ?? GameLogic(config: config ?? const GameConfig()),
    ),
    ballState = BallState(
      config: config ?? const GameConfig(),
      logic: logic ?? GameLogic(config: config ?? const GameConfig()),
    );
  
  // 重置遊戲
  void resetGame() {
    boardState.resetBoard();
    ballState.resetBalls();
  }
  
  // 開始遊戲
  void startGame(TickerProvider vsync, double cellSize) {
    ballState.startGame();
    
    // 啟動小球動畫
    ballState.simulateBallMovement(
      vsync: vsync,
      cellSize: cellSize,
      modules: boardState.modules,
    );
  }
  
  // 設置遊戲模式
  void setGameMode(GameMode mode) {
    ballState.gameMode = mode;
    boardState.resetBoard(); // 切換模式時重置棋盤
  }
} 