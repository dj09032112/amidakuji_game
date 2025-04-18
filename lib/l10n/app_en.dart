import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// 英文本地化
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn(Locale locale) : super(locale);
  
  @override
  String get appTitle => 'Amidakuji Game';
  
  @override
  String get resetGame => 'Reset Game';
  
  @override
  String get startGame => 'Start';
  
  @override
  String get gameInProgress => 'In Progress';
  
  @override
  String get newGame => 'New Game';
  
  @override
  String get gameMode => 'Game Mode:';
  
  @override
  String get singleBallMode => 'Single Ball';
  
  @override
  String get multiBallMode => 'Multi Ball';
  
  @override
  String get singleBallSuccess => 'Congratulations! The ball reached the destination!';
  
  @override
  String get multiBallSuccess => 'Congratulations! All balls reached their correct destinations!';
  
  @override
  String get singleBallFailure => 'Sorry! The ball didn\'t reach the correct destination!';
  
  @override
  String get multiBallFailure => 'Sorry! Not all balls reached their correct destinations!';
  
  @override
  String get toolboxTitle => 'Module Toolbox';
  
  @override
  String get horizontalModule => 'Horizontal Line';
  
  @override
  String get bridgeModule => 'Bridge Module';
  
  @override
  String get singleBallHint => 'Tip: Drag modules from the toolbox to help the ball reach its destination';
  
  @override
  String get multiBallHint => 'Tip: Drag modules from the toolbox to help all balls reach their correct destinations';
}