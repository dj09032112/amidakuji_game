import 'dart:math';
import 'package:flutter/material.dart';
import 'game_module.dart';
import 'game_config.dart';
import '../utils/grid_mapper.dart';

/// 遊戲邏輯類，負責處理核心遊戲邏輯和運算，不包含狀態管理
class GameLogic {
  final GameConfig config;
  
  /// 建構子
  GameLogic({required this.config});
  
  /// 生成隨機起點和終點 (單球模式)
  Map<String, int> generateSingleBallPoints() {
    Random random = Random();
    return {
      'startColumn': random.nextInt(config.columns),
      'targetColumn': random.nextInt(config.columns),
    };
  }
  
  /// 生成隨機起點和終點 (多球模式)
  Map<String, List<int>> generateMultiBallPoints() {
    Random random = Random();
    
    // 生成 0-(multiBallCount-1) 的隨機排列作為終點順序
    List<int> targetOrder = List.generate(config.multiBallCount, (index) => index);
    targetOrder.shuffle(random);
    
    // 設置起點和終點
    List<int> startColumns = List.generate(config.multiBallCount, (index) => index);
    
    return {
      'startColumns': startColumns,
      'endColumns': targetOrder,
    };
  }
  
  /// 檢查模塊是否在有效範圍內
  bool isModuleInValidRange(GameModule module) {
    final gridMapper = GridMapper(
      cellSize: 1.0, // 這裡實際尺寸不重要，只需要檢查邏輯
      rows: config.rows,
      columns: config.columns,
    );
    
    return gridMapper.isValidGridPosition(module.position) && 
           module.position.column + module.width - 1 < config.columns;
  }
  
  /// 檢查模塊是否與其他模塊衝突
  bool hasModuleConflict(GameModule module, List<GameModule> existingModules) {
    for (var existingModule in existingModules) {
      if (module.intersectsWith(existingModule)) {
        return true;
      }
    }
    return false;
  }
  
  /// 計算球的詳細移動路徑，包括所有轉彎點
  List<PathPoint> calculateBallPath({
    required List<GameModule> modules,
    required int startColumn,
    required double cellSize,
  }) {
    List<PathPoint> detailedPath = [];
    int col = startColumn;
    
    final gridMapper = GridMapper(
      cellSize: cellSize,
      rows: config.rows,
      columns: config.columns,
    );
    
    // 從底部向上移動
    for (int row = config.rows - 1; row >= 0; row--) {
      bool hasTurned = false;
      Position currentGridPos = Position(row, col);
      
      // 檢查當前行是否有模塊
      for (var module in modules.where((m) => m.position.row == row)) {
        if (module.type == ModuleType.horizontal) {
          if (module.position.column == col) {
            // 如果模塊起點與當前列相同，往右移
            
            // 先到達模塊所在行的中心點
            final centerPos = _getBallPositionInCell(currentGridPos, gridMapper);
            detailedPath.add(PathPoint(centerPos.dx, centerPos.dy, false));
            
            // 然後水平向右移動到下一列的中心點
            final nextPos = _getBallPositionInCell(Position(row, col + 1), gridMapper);
            detailedPath.add(PathPoint(nextPos.dx, nextPos.dy, true));
            
            col++;
            hasTurned = true;
            break;
          } else if (module.position.column + 1 == col) {
            // 如果模塊終點與當前列相同，往左移
            
            // 先到達模塊所在行的中心點
            final centerPos = _getBallPositionInCell(currentGridPos, gridMapper);
            detailedPath.add(PathPoint(centerPos.dx, centerPos.dy, false));
            
            // 然後水平向左移動到下一列的中心點
            final nextPos = _getBallPositionInCell(Position(row, col - 1), gridMapper);
            detailedPath.add(PathPoint(nextPos.dx, nextPos.dy, true));
            
            col--;
            hasTurned = true;
            break;
          }
        } else if (module.type == ModuleType.bridge) {
          if (module.position.column == col) {
            // 如果橋的起點與當前列相同，跳過中間一列
            
            // 先到達模塊所在行的中心點
            final centerPos = _getBallPositionInCell(currentGridPos, gridMapper);
            detailedPath.add(PathPoint(centerPos.dx, centerPos.dy, false));
            
            // 然後水平向右移動跨越中間列，到達橋的終點中心點
            final nextPos = _getBallPositionInCell(Position(row, col + 2), gridMapper);
            detailedPath.add(PathPoint(nextPos.dx, nextPos.dy, true));
            
            col += 2;
            hasTurned = true;
            break;
          } else if (module.position.column + 2 == col) {
            // 如果橋的終點與當前列相同，跳過中間一列
            
            // 先到達模塊所在行的中心點
            final centerPos = _getBallPositionInCell(currentGridPos, gridMapper);
            detailedPath.add(PathPoint(centerPos.dx, centerPos.dy, false));
            
            // 然後水平向左移動跨越中間列，到達橋的起點中心點
            final nextPos = _getBallPositionInCell(Position(row, col - 2), gridMapper);
            detailedPath.add(PathPoint(nextPos.dx, nextPos.dy, true));
            
            col -= 2;
            hasTurned = true;
            break;
          }
        }
      }
      
      // 如果沒有轉彎，添加正常向上移動的路徑點
      if (!hasTurned) {
        final centerPos = _getBallPositionInCell(currentGridPos, gridMapper);
        detailedPath.add(PathPoint(centerPos.dx, centerPos.dy, false));
      }
    }
    
    // 返回最終列位置和路徑
    return detailedPath;
  }
  
  // 計算球在指定網格位置的中心坐標
  Offset _getBallPositionInCell(Position gridPosition, GridMapper gridMapper) {
    final centerPixel = gridMapper.gridToPixelCenter(gridPosition);
    // 調整球的大小偏移
    return Offset(
      centerPixel.dx - (gridMapper.cellSize * 0.6 / 2),
      centerPixel.dy - (gridMapper.cellSize * 0.6 / 2),
    );
  }
  
  /// 根據路徑計算最終列位置
  int calculateFinalColumn(List<PathPoint> path, double cellSize) {
    if (path.isEmpty) return 0;
    
    final lastPoint = path.last;
    
    final gridMapper = GridMapper(
      cellSize: cellSize,
      rows: config.rows,
      columns: config.columns,
    );
    
    // 使用 GridMapper 從像素坐標計算列號
    final offset = Offset(
      lastPoint.x + (cellSize * 0.6 / 2), // 加回球的半徑偏移，得到中心點
      lastPoint.y + (cellSize * 0.6 / 2)
    );
    
    return gridMapper.pixelToGrid(offset).column;
  }
  
  /// 檢查所有球是否都到達正確的終點 (多球模式)
  bool areAllBallsReachedCorrectTarget(List<int> finalColumns, List<int> targetColumns) {
    if (finalColumns.length != targetColumns.length) return false;
    
    for (int i = 0; i < finalColumns.length; i++) {
      if (finalColumns[i] != targetColumns[i]) {
        return false;
      }
    }
    return true;
  }
}

/// 表示路徑上的一個點，含有精確的像素坐標
class PathPoint {
  final double x;
  final double y;
  final bool isTurningPoint;
  
  PathPoint(this.x, this.y, this.isTurningPoint);
} 