import 'package:flutter/material.dart';
import '../models/game_module.dart';

/// 網格映射器 - 負責網格座標與像素座標的轉換
class GridMapper {
  final double cellSize;
  final int rows;
  final int columns;

  const GridMapper({
    required this.cellSize,
    required this.rows,
    required this.columns,
  });

  /// 檢查網格位置是否合法
  bool isValidPosition(int row, int column) {
    return row >= 0 && row < rows && column >= 0 && column < columns;
  }

  /// 檢查網格位置是否合法 (Position 物件)
  bool isValidGridPosition(Position position) {
    return isValidPosition(position.row, position.column);
  }

  /// 將像素座標轉換為網格座標
  Position pixelToGrid(Offset pixelPosition) {
    final row = (pixelPosition.dy / cellSize).floor();
    final column = (pixelPosition.dx / cellSize).floor();
    return Position(row, column);
  }

  /// 將拖動事件的位置轉換為網格座標
  Position dragPositionToGrid(Offset dragPosition) {
    final row = ((dragPosition.dy + cellSize / 2) / cellSize).floor();
    final column = ((dragPosition.dx + cellSize / 2) / cellSize).floor();
    return Position(row, column);
  }

  /// 將網格座標轉換為左上角像素座標
  Offset gridToPixel(Position gridPosition) {
    return Offset(
      gridPosition.column * cellSize,
      gridPosition.row * cellSize,
    );
  }

  /// 將網格座標轉換為中心像素座標
  Offset gridToPixelCenter(Position gridPosition) {
    return Offset(
      gridPosition.column * cellSize + cellSize / 2,
      gridPosition.row * cellSize + cellSize / 2,
    );
  }

  /// 計算球的開始位置
  Offset calculateBallStartPosition(int column) {
    return Offset(
      column * cellSize + cellSize / 2 - (cellSize * 0.6 / 2),
      rows * cellSize - cellSize / 2 - (cellSize * 0.6 / 2)
    );
  }

  /// 取得模塊在網格中的寬度 (以像素為單位)
  double getModuleWidth(ModuleType type) {
    final int width = type == ModuleType.horizontal ? 2 : 3;
    return width * cellSize;
  }

  /// 取得終點位置的左上角座標
  Offset getEndPointPosition(int column) {
    return Offset(column * cellSize, 0);
  }

  /// 計算格子內的起點圓球位置
  Offset calculateStartPointPosition(int column) {
    return Offset(
      column * cellSize + (cellSize - cellSize * 0.6) / 2,
      rows * cellSize - cellSize / 2 - cellSize * 0.3
    );
  }
} 