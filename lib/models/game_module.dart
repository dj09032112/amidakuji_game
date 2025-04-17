enum ModuleType {
  horizontal, // 橫線模塊
  bridge, // 橋接模塊
}

class Position {
  final int row;
  final int column;

  Position(this.row, this.column);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Position && other.row == row && other.column == column;
  }

  @override
  int get hashCode => row.hashCode ^ column.hashCode;

  @override
  String toString() => 'Position($row, $column)';
}

class GameModule {
  ModuleType type;
  Position position;

  // 用於記錄模塊寬度和高度
  int get width => type == ModuleType.horizontal ? 2 : 3; // 橫線寬2格，橋接寬3格
  int get height => 1; // 所有模塊高度都是1格

  GameModule({required this.type, required this.position});

  // 用於檢查兩個模塊是否位置衝突
  bool intersectsWith(GameModule other) {
    // 檢查兩個模塊是否在同一行且位置有重疊
    if (position.row != other.position.row) return false;
    
    int thisLeft = position.column;
    int thisRight = position.column + width - 1;
    int otherLeft = other.position.column;
    int otherRight = other.position.column + other.width - 1;
    
    return !(thisRight < otherLeft || thisLeft > otherRight);
  }
} 