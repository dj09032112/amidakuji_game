# 鬼腳圖遊戲 (Amidakuji)

這是一個使用 Flutter 開發的鬼腳圖（又稱「爬梯子」或 Amidakuji）邏輯遊戲。

## 功能介紹

- 5 欄 x 8 列的遊戲棋盤
- 兩種可拖曳放置的模塊：
  - 橫線模塊：寬 2 格、高 1 格，讓球左右轉彎
  - 橋接模塊：寬 3 格、高 1 格，讓球跨越中間欄位
- 模塊可以刪除和重新放置
- 隨機生成起點和終點
- 小球從底部起點出發，沿路徑向上移動，最終判定是否到達指定終點

## 專案結構

```
lib/
  ├── main.dart              # 應用程序入口點
  ├── models/                # 資料模型
  │   ├── game_module.dart   # 模塊類型和位置模型
  │   └── game_state.dart    # 遊戲狀態管理
  ├── screens/               # 頁面
  │   └── game_screen.dart   # 主遊戲頁面
  ├── widgets/               # UI元件
  │   ├── game_board.dart    # 遊戲棋盤
  │   ├── module_widget.dart # 模塊顯示元件
  │   └── tool_panel.dart    # 工具面板
  └── utils/                 # 工具類
      └── ball_animation.dart # 小球動畫控制
```

## 運行方式

確保您已安裝 Flutter 環境，然後執行：

```bash
flutter pub get
flutter run
```

## 遊戲玩法

1. 從下方工具箱拖曳模塊放到棋盤上
2. 模塊可以點擊刪除或重新放置
3. 設定好路徑後，點擊「開始」按鈕
4. 小球會從底部起點出發，沿著路徑向上移動
5. 根據小球是否到達指定終點，顯示成功或失敗提示
6. 點擊重置按鈕開始新一輪遊戲 