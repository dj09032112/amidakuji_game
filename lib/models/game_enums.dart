/// 遊戲狀態枚舉
enum GameStatus {
  ready,    // 遊戲準備中
  running,  // 遊戲運行中
  success,  // 遊戲成功
  failure,  // 遊戲失敗
}

/// 遊戲模式枚舉
enum GameMode {
  singleMatch, // 單球模式
  multiMatch,  // 多球模式
} 