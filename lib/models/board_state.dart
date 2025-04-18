import 'package:flutter/material.dart';
import 'game_module.dart';
import 'game_config.dart';
import 'game_logic.dart';

/// 棋盤狀態類，負責管理棋盤上的模塊及其位置
class BoardState with ChangeNotifier {
  // 遊戲配置
  final GameConfig config;

  // 遊戲邏輯引用
  final GameLogic logic;

  // 模塊列表
  List<GameModule> _modules = [];

  // 構造函數
  BoardState({
    required this.config,
    required this.logic,
  });

  // Getter 方法
  List<GameModule> get modules => _modules;

  // 重置棋盤
  void resetBoard() {
    _modules.clear();
    notifyListeners();
  }

  // 添加模塊
  bool addModule(GameModule module) {
    // 使用GameLogic檢查模塊是否在有效範圍內
    if (!logic.isModuleInValidRange(module)) {
      return false;
    }
    
    // 使用GameLogic檢查是否與現有模塊衝突
    if (logic.hasModuleConflict(module, _modules)) {
      return false;
    }
    
    _modules.add(module);
    notifyListeners();
    return true;
  }
  
  // 移除模塊
  void removeModule(Position position) {
    _modules.removeWhere((module) => 
      module.position.row == position.row && 
      module.position.column <= position.column && 
      module.position.column + module.width > position.column
    );
    notifyListeners();
  }
} 