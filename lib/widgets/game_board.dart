import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_module.dart';
import '../models/game_state.dart';
import 'module_widget.dart';

class GameBoard extends StatefulWidget {
  final double cellSize;

  const GameBoard({Key? key, this.cellSize = 50.0}) : super(key: key);

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // 跟踪預覽模塊的位置
  Position? previewPosition;
  ModuleType? previewType;
  
  // 跟踪正在移動的方塊
  GameModule? movingModule;
  int? movingModuleIndex;
  
  @override
  Widget build(BuildContext context) {
    // 在 build 方法中獲取 context，這是合法的位置
    final gameState = Provider.of<GameState>(context);
    final boardWidth = gameState.columns * widget.cellSize;
    final boardHeight = gameState.rows * widget.cellSize;

    return Container(
      width: boardWidth,
      height: boardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.0),
      ),
      child: Stack(
        children: [
          // 繪製豎線網格
          _buildVerticalLines(gameState),
          
          // 繪製已放置模塊
          ...gameState.modules.asMap().entries.map((entry) => 
            entry.value != movingModule 
              ? _buildPlacedModule(entry.key, entry.value, gameState) 
              : const SizedBox.shrink()
          ),
          
          // 繪製預覽模塊（如果有）
          if (previewPosition != null && previewType != null)
            _buildPreviewModule(previewPosition!, previewType!),
          
          // 繪製正在移動的模塊（如果有）
          if (movingModule != null)
            _buildMovingModule(movingModule!, gameState),
          
          // 根據遊戲模式繪製起點終點和小球
          if (gameState.gameMode == GameMode.singleMatch && 
              (gameState.status == GameStatus.running || 
               gameState.status == GameStatus.success || 
               gameState.status == GameStatus.failure))
            _buildBall(gameState),
          
          if (gameState.gameMode == GameMode.singleMatch)
            _buildStartPoint(gameState),
          
          if (gameState.gameMode == GameMode.singleMatch)
            _buildEndPoint(gameState),
          
          if (gameState.gameMode == GameMode.multiMatch && 
              (gameState.status == GameStatus.running || 
               gameState.status == GameStatus.success || 
               gameState.status == GameStatus.failure))
            _buildMultiBalls(gameState),
          
          if (gameState.gameMode == GameMode.multiMatch)
            _buildMultiStartPoints(gameState),
          
          if (gameState.gameMode == GameMode.multiMatch)
            _buildMultiEndPoints(gameState),
          
          // 處理放置模塊的事件，傳入 context
          _buildDropTarget(context, gameState),
        ],
      ),
    );
  }

  // 繪製垂直線
  Widget _buildVerticalLines(GameState gameState) {
    return CustomPaint(
      size: Size(gameState.columns * widget.cellSize, gameState.rows * widget.cellSize),
      painter: VerticalLinesPainter(
        columns: gameState.columns,
        rows: gameState.rows,
        cellSize: widget.cellSize,
      ),
    );
  }

  // 繪製已放置的模塊
  Widget _buildPlacedModule(int index, GameModule module, GameState gameState) {
    // 只有遊戲準備階段才能移動方塊
    bool canMove = gameState.status == GameStatus.ready;
    
    return Positioned(
      left: module.position.column * widget.cellSize,
      top: module.position.row * widget.cellSize,
      child: GestureDetector(
        onTap: () {
          gameState.removeModule(module.position);
        },
        onPanStart: canMove ? (details) {
          // 開始拖動，記錄當前模塊
          setState(() {
            movingModule = module;
            movingModuleIndex = index;
          });
        } : null,
        onPanUpdate: canMove ? (details) {
          // 計算拖動位置對應的網格位置
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          
          // 計算放置的行列位置
          int row = ((localPosition.dy + widget.cellSize / 2) / widget.cellSize).floor();
          int column = ((localPosition.dx + widget.cellSize / 2) / widget.cellSize).floor();
          
          // 確保位置在網格範圍內並且與原位置不同
          if (row >= 0 && row < gameState.rows && 
              column >= 0 && column < gameState.columns &&
              (row != module.position.row || column != module.position.column)) {
            setState(() {
              // 更新預覽位置
              previewPosition = Position(row, column);
              previewType = module.type;
            });
          } else {
            setState(() {
              previewPosition = null;
              previewType = null;
            });
          }
        } : null,
        onPanEnd: canMove ? (details) {
          // 釋放方塊，嘗試放置到新位置
          if (previewPosition != null && previewType != null && movingModule != null) {
            // 臨時移除原模塊
            gameState.modules.removeAt(movingModuleIndex!);
            
            // 創建新模塊
            GameModule newModule = GameModule(
              type: previewType!,
              position: previewPosition!,
            );
            
            // 嘗試放置到新位置
            bool placed = gameState.addModule(newModule);
            
            // 如果放置失敗，還原原模塊
            if (!placed) {
              gameState.modules.insert(movingModuleIndex!, movingModule!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('無法移動到此位置'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
          
          // 清理狀態
          setState(() {
            movingModule = null;
            movingModuleIndex = null;
            previewPosition = null;
            previewType = null;
          });
        } : null,
        child: ModuleWidget(
          type: module.type,
          width: module.width * widget.cellSize,
          height: module.height * widget.cellSize,
          isPlaced: true,
        ),
      ),
    );
  }
  
  // 繪製正在移動中的模塊
  Widget _buildMovingModule(GameModule module, GameState gameState) {
    return Positioned(
      left: module.position.column * widget.cellSize,
      top: module.position.row * widget.cellSize,
      child: Opacity(
        opacity: 0.3, // 半透明表示正在移動
        child: ModuleWidget(
          type: module.type,
          width: module.width * widget.cellSize,
          height: module.height * widget.cellSize,
          isPlaced: true,
        ),
      ),
    );
  }
  
  // 繪製預覽模塊
  Widget _buildPreviewModule(Position position, ModuleType type) {
    final int width = type == ModuleType.horizontal ? 2 : 3;
    
    return Positioned(
      left: position.column * widget.cellSize,
      top: position.row * widget.cellSize,
      child: Opacity(
        opacity: 0.5, // 半透明預覽
        child: ModuleWidget(
          type: type,
          width: width * widget.cellSize,
          height: widget.cellSize,
          isPlaced: false,
        ),
      ),
    );
  }

  // 繪製單個小球
  Widget _buildBall(GameState gameState) {
    return Positioned(
      left: gameState.ballPositionX,
      top: gameState.ballPositionY,
      child: Container(
        width: widget.cellSize * 0.6,
        height: widget.cellSize * 0.6,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // 繪製多個小球
  Widget _buildMultiBalls(GameState gameState) {
    return Stack(
      children: List.generate(5, (index) {
        // 使用不同的顏色區分不同的球
        Color ballColor = _getBallColor(index);
        
        return Positioned(
          left: gameState.ballPositionsX[index],
          top: gameState.ballPositionsY[index],
          child: Container(
            width: widget.cellSize * 0.6,
            height: widget.cellSize * 0.6,
            decoration: BoxDecoration(
              color: ballColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  // 繪製單個起點
  Widget _buildStartPoint(GameState gameState) {
    // 只在遊戲準備階段顯示起點的球
    if (gameState.status != GameStatus.ready) {
      return const SizedBox.shrink(); // 遊戲運行中或結束後不顯示起點球
    }
    
    return Positioned(
      left: gameState.currentColumn * widget.cellSize + (widget.cellSize - widget.cellSize * 0.6) / 2,
      top: gameState.rows * widget.cellSize - widget.cellSize / 2 - widget.cellSize * 0.3,
      child: Container(
        width: widget.cellSize * 0.6,
        height: widget.cellSize * 0.6,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // 繪製多個起點
  Widget _buildMultiStartPoints(GameState gameState) {
    // 只在遊戲準備階段顯示起點的球
    if (gameState.status != GameStatus.ready) {
      return const SizedBox.shrink(); // 遊戲運行中或結束後不顯示起點球
    }
    
    return Stack(
      children: List.generate(5, (index) {
        Color ballColor = _getBallColor(index);
        
        return Positioned(
          left: gameState.startColumns[index] * widget.cellSize + (widget.cellSize - widget.cellSize * 0.6) / 2,
          top: gameState.rows * widget.cellSize - widget.cellSize / 2 - widget.cellSize * 0.3,
          child: Container(
            width: widget.cellSize * 0.6,
            height: widget.cellSize * 0.6,
            decoration: BoxDecoration(
              color: ballColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  // 繪製單個終點
  Widget _buildEndPoint(GameState gameState) {
    return Positioned(
      left: gameState.targetColumn * widget.cellSize,
      top: 0,
      child: Container(
        width: widget.cellSize,
        height: widget.cellSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          border: Border.all(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  // 繪製多個終點
  Widget _buildMultiEndPoints(GameState gameState) {
    return Stack(
      children: List.generate(5, (index) {
        Color ballColor = _getBallColor(index);
        
        return Positioned(
          left: gameState.endColumns[index] * widget.cellSize,
          top: 0,
          child: Container(
            width: widget.cellSize,
            height: widget.cellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ballColor.withOpacity(0.2),
              border: Border.all(color: ballColor, width: 2),
            ),
          ),
        );
      }),
    );
  }
  
  // 獲取不同球的顏色
  Color _getBallColor(int index) {
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    
    return colors[index % colors.length];
  }

  // 處理拖曳放置模塊的區域
  Widget _buildDropTarget(BuildContext context, GameState gameState) {
    return SizedBox(
      width: gameState.columns * widget.cellSize,
      height: gameState.rows * widget.cellSize,
      child: DragTarget<ModuleType>(
        builder: (context, candidateData, rejectedData) {
          return Container(color: Colors.transparent);
        },
        // 當拖曳進入區域時顯示預覽
        onWillAccept: (data) {
          return data != null && gameState.status == GameStatus.ready;
        },
        // 拖曳移動時更新預覽位置
        onMove: (details) {
          // 只有遊戲準備階段才接受拖放
          if (gameState.status != GameStatus.ready) return;
          
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          
          // 計算放置的行列位置
          int row = ((localPosition.dy + widget.cellSize / 2) / widget.cellSize).floor();
          int column = ((localPosition.dx + widget.cellSize / 2) / widget.cellSize).floor();
          
          // 確保位置在網格範圍內
          if (row >= 0 && row < gameState.rows && column >= 0 && column < gameState.columns) {
            setState(() {
              previewPosition = Position(row, column);
              previewType = details.data;
            });
          } else {
            setState(() {
              previewPosition = null;
              previewType = null;
            });
          }
        },
        // 退出拖曳區域
        onLeave: (data) {
          setState(() {
            previewPosition = null;
            previewType = null;
          });
        },
        onAcceptWithDetails: (details) {
          // 只有遊戲準備階段才接受拖放
          if (gameState.status != GameStatus.ready) return;
          
          // 使用傳入的 context 參數，這是從 build 方法傳遞下來的合法 context
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          
          // 計算放置的行列位置
          int row = ((localPosition.dy + widget.cellSize / 2) / widget.cellSize).floor();
          int column = ((localPosition.dx + widget.cellSize / 2) / widget.cellSize).floor();
          
          // 確保位置在網格範圍內
          if (row >= 0 && row < gameState.rows && column >= 0 && column < gameState.columns) {
            // 建立新模塊
            GameModule newModule = GameModule(
              type: details.data,
              position: Position(row, column),
            );
            
            // 嘗試放置模塊
            bool placed = gameState.addModule(newModule);
            
            // 清除預覽
            setState(() {
              previewPosition = null;
              previewType = null;
            });
            
            // 如果放置失敗，可以顯示提示訊息
            if (!placed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('無法放置模塊在此位置'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// 用於繪製垂直線的 CustomPainter
class VerticalLinesPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellSize;

  VerticalLinesPainter({
    required this.columns,
    required this.rows,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 繪製每條垂直線
    for (int col = 0; col < columns; col++) {
      double x = col * cellSize + cellSize / 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, rows * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 