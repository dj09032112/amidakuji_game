import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// 繁體中文本地化
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh(Locale locale) : super(locale);
  
  @override
  String get appTitle => '爬梯子遊戲';
  
  @override
  String get resetGame => '重置遊戲';
  
  @override
  String get startGame => '開始';
  
  @override
  String get gameInProgress => '進行中';
  
  @override
  String get newGame => '新遊戲';
  
  @override
  String get gameMode => '遊戲模式：';
  
  @override
  String get singleBallMode => '單球模式';
  
  @override
  String get multiBallMode => '多球模式';
  
  @override
  String get singleBallSuccess => '恭喜！小球成功到達終點！';
  
  @override
  String get multiBallSuccess => '恭喜！所有小球都正確到達終點！';
  
  @override
  String get singleBallFailure => '可惜！小球沒有到達指定終點！';
  
  @override
  String get multiBallFailure => '可惜！不是所有小球都到達正確終點！';
  
  @override
  String get toolboxTitle => '模塊工具箱';
  
  @override
  String get horizontalModule => '橫線模塊';
  
  @override
  String get bridgeModule => '橋接模塊';
  
  @override
  String get singleBallHint => '提示：從工具箱中拖曳模塊到棋盤上，幫助小球從起點到達終點';
  
  @override
  String get multiBallHint => '提示：從工具箱中拖曳模塊到棋盤上，幫助所有小球從各自起點到達對應終點';
}