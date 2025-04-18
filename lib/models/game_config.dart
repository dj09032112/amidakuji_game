import '../constants.dart';

/// 遊戲配置類，負責管理遊戲相關的固定配置和常數
class GameConfig {
  // 網格尺寸
  final int columns;
  final int rows;
  
  // 球的移動速度（單位：像素/秒）
  final double ballSpeed;
  
  // 多球模式中球的數量
  final int multiBallCount;

  const GameConfig({
    this.columns = AppConstants.defaultColumns,
    this.rows = AppConstants.defaultRows,
    this.ballSpeed = AppConstants.defaultBallSpeed,
    this.multiBallCount = AppConstants.defaultMultiBallCount,
  });
} 