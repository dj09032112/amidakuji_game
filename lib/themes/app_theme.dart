import 'package:flutter/material.dart';
import '../models/game_module.dart';

/// 應用主題與樣式統一管理
class AppTheme {
  // 遊戲板相關顏色
  static const Color kGridBackground = Colors.white;
  static const Color kGridBorder = Colors.black;
  static const Color kGridLine = Colors.black;
  
  // 模塊相關顏色
  static const Color kHorizontalModule = Colors.orange;
  static const Color kBridgeModule = Colors.purple;
  static const Color kModuleBorder = Colors.black;
  
  // 球相關顏色
  static const Color kBallRed = Colors.red;
  static const Color kBallBlue = Colors.blue;
  static const Color kBallGreen = Colors.green;
  static const Color kBallOrange = Colors.orange;
  static const Color kBallPurple = Colors.purple;
  static const Color kBallBorder = Colors.black;
  
  // 終點相關顏色
  static const Color kEndpointRed = Colors.red;
  
  // 工具箱相關顏色
  static const Color kToolboxBackground = Color(0xFFEEEEEE);
  static const Color kToolboxShadow = Colors.black12;
  
  // 線條粗細
  static const double kGridLineThickness = 2.0;
  static const double kModuleBorderThickness = 1.5;
  static const double kBallBorderThickness = 2.0;
  static const double kEndpointBorderThickness = 2.0;
  static const double kModuleContentThickness = 3.0;
  
  // 圓角
  static const double kModuleCornerRadius = 4.0;
  static const double kToolboxCornerRadius = 8.0;
  
  // 透明度
  static const double kPlacedModuleOpacity = 0.8;
  static const double kUnplacedModuleOpacity = 0.6;
  static const double kPreviewModuleOpacity = 0.5;
  static const double kDraggingOpacity = 0.3;
  static const double kEndpointBackgroundOpacity = 0.2;
  
  // 字體大小
  static const double kToolboxTitleSize = 15.0;
  static const double kToolboxLabelSize = 12.0;
  
  // 填充
  static const EdgeInsets kToolboxPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0);
  static const double kToolboxSpacing = 8.0;
  static const double kToolItemSpacing = 4.0;
  static const double kToolItemMargin = 12.0;
  
  // 文字樣式
  static const TextStyle kToolboxTitleStyle = TextStyle(
    fontSize: kToolboxTitleSize,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle kToolboxLabelStyle = TextStyle(
    fontSize: kToolboxLabelSize,
  );
  
  // 多彩小球顏色列表
  static List<Color> getBallColors() {
    return [
      kBallRed,
      kBallBlue,
      kBallGreen,
      kBallOrange,
      kBallPurple,
    ];
  }
  
  // 根據模塊類型取得顏色
  static Color getModuleColor(ModuleType type, {bool isPlaced = false}) {
    final Color baseColor = (type == ModuleType.horizontal)
        ? kHorizontalModule
        : kBridgeModule;
    
    return baseColor.withOpacity(isPlaced ? kPlacedModuleOpacity : kUnplacedModuleOpacity);
  }
} 