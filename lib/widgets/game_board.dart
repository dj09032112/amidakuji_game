import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_module.dart';
import '../models/board_state.dart';
import '../models/ball_state.dart';
import '../models/game_config.dart';
import '../models/game_enums.dart';
import '../utils/grid_mapper.dart';
import '../themes/app_theme.dart';
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
  
  // 取得 GridMapper 實例
  GridMapper _getGridMapper(GameConfig config) {
    return GridMapper(
      cellSize: widget.cellSize,
      rows: config.rows,
      columns: config.columns,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final boardState = Provider.of<BoardState>(context);
    final ballState = Provider.of<BallState>(context);
    final gridMapper = _getGridMapper(boardState.config);
    final boardWidth = boardState.config.columns * widget.cellSize;
    final boardHeight = boardState.config.rows * widget.cellSize;

    return Container(
      width: boardWidth,
      height: boardHeight,
      decoration: BoxDecoration(
        color: AppTheme.kGridBackground,
        border: Border.all(
          color: AppTheme.kGridBorder, 
          width: AppTheme.kGridLineThickness,
        ),
      ),
      child: Stack(
        children: [
          _buildVerticalLines(boardState.config),
          
          ...boardState.modules.asMap().entries.map((entry) => 
            entry.value != movingModule 
              ? _buildPlacedModule(entry.key, entry.value, boardState, ballState, gridMapper) 
              : const SizedBox.shrink()
          ),
          
          if (previewPosition != null && previewType != null)
            _buildPreviewModule(previewPosition!, previewType!, gridMapper),
          
          if (movingModule != null)
            _buildMovingModule(movingModule!, gridMapper),
          
          if (ballState.gameMode == GameMode.singleMatch && 
              (ballState.status == GameStatus.running || 
               ballState.status == GameStatus.success || 
               ballState.status == GameStatus.failure))
            _buildBall(ballState.ballPositionX, ballState.ballPositionY, AppTheme.kBallRed),
          
          if (ballState.gameMode == GameMode.singleMatch)
            _buildStartPoint(ballState, gridMapper),
          
          if (ballState.gameMode == GameMode.singleMatch)
            _buildEndPoint(ballState, gridMapper),
          
          if (ballState.gameMode == GameMode.multiMatch && 
              (ballState.status == GameStatus.running || 
               ballState.status == GameStatus.success || 
               ballState.status == GameStatus.failure))
            _buildMultiBalls(ballState),
          
          if (ballState.gameMode == GameMode.multiMatch)
            _buildMultiStartPoints(ballState, gridMapper),
          
          if (ballState.gameMode == GameMode.multiMatch)
            _buildMultiEndPoints(ballState, gridMapper),
          
          _buildDropTarget(context, boardState, ballState, gridMapper),
        ],
      ),
    );
  }

  // 繪製垂直線
  Widget _buildVerticalLines(GameConfig config) {
    return CustomPaint(
      size: Size(config.columns * widget.cellSize, config.rows * widget.cellSize),
      painter: VerticalLinesPainter(
        columns: config.columns,
        rows: config.rows,
        cellSize: widget.cellSize,
      ),
    );
  }

  // 繪製已放置的模塊
  Widget _buildPlacedModule(int index, GameModule module, BoardState boardState, BallState ballState, GridMapper gridMapper) {
    bool canMove = ballState.status == GameStatus.ready;
    final pixelPosition = gridMapper.gridToPixel(module.position);
    
    return Positioned(
      left: pixelPosition.dx,
      top: pixelPosition.dy,
      child: GestureDetector(
        onTap: () => boardState.removeModule(module.position),
        onPanStart: canMove ? (details) {
          setState(() {
            movingModule = module;
            movingModuleIndex = index;
          });
        } : null,
        onPanUpdate: canMove ? (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          
          final position = gridMapper.dragPositionToGrid(localPosition);
          
          if (gridMapper.isValidGridPosition(position) &&
              (position.row != module.position.row || position.column != module.position.column)) {
            setState(() {
              previewPosition = position;
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
          if (previewPosition != null && previewType != null) {
            final newModule = GameModule(
              type: previewType!,
              position: previewPosition!,
            );
            
            boardState.removeModule(module.position);
            bool success = boardState.addModule(newModule);
            if (!success) {
              boardState.addModule(module);
            }
          }
          
          setState(() {
            previewPosition = null;
            previewType = null;
            movingModule = null;
            movingModuleIndex = null;
          });
        } : null,
        child: ModuleWidget(
          type: module.type,
          width: gridMapper.getModuleWidth(module.type),
          height: widget.cellSize,
          isPlaced: true,
        ),
      ),
    );
  }
  
  // 繪製正在移動的模塊
  Widget _buildMovingModule(GameModule module, GridMapper gridMapper) {
    final pixelPosition = gridMapper.gridToPixel(module.position);
    
    return Positioned(
      left: pixelPosition.dx,
      top: pixelPosition.dy,
      child: Opacity(
        opacity: 0.0,
        child: ModuleWidget(
          type: module.type,
          width: gridMapper.getModuleWidth(module.type),
          height: widget.cellSize,
          isPlaced: true,
        ),
      ),
    );
  }
  
  // 繪製模塊預覽
  Widget _buildPreviewModule(Position position, ModuleType type, GridMapper gridMapper) {
    final pixelPosition = gridMapper.gridToPixel(position);
    
    return Positioned(
      left: pixelPosition.dx,
      top: pixelPosition.dy,
      child: Opacity(
        opacity: AppTheme.kPreviewModuleOpacity,
        child: ModuleWidget(
          type: type,
          width: gridMapper.getModuleWidth(type),
          height: widget.cellSize,
          isPlaced: false,
        ),
      ),
    );
  }

  // 通用的小球渲染方法
  Widget _buildBall(double x, double y, Color color, {bool hasBorder = false}) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: widget.cellSize * 0.6,
        height: widget.cellSize * 0.6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(
            color: AppTheme.kBallBorder,
            width: AppTheme.kBallBorderThickness,
          ) : null,
        ),
      ),
    );
  }

  // 繪製多個小球
  Widget _buildMultiBalls(BallState ballState) {
    return Stack(
      children: List.generate(ballState.config.multiBallCount, (index) {
        Color ballColor = _getBallColor(index);
        return _buildBall(
          ballState.ballPositionsX[index],
          ballState.ballPositionsY[index],
          ballColor,
          hasBorder: true,
        );
      }),
    );
  }

  // 繪製單個起點
  Widget _buildStartPoint(BallState ballState, GridMapper gridMapper) {
    if (ballState.status != GameStatus.ready) {
      return const SizedBox.shrink();
    }
    
    final position = gridMapper.calculateStartPointPosition(ballState.currentColumn);
    
    return _buildBall(
      position.dx,
      position.dy,
      AppTheme.kBallRed,
    );
  }

  // 繪製多個起點
  Widget _buildMultiStartPoints(BallState ballState, GridMapper gridMapper) {
    if (ballState.status != GameStatus.ready) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: List.generate(ballState.config.multiBallCount, (index) {
        Color ballColor = _getBallColor(index);
        final position = gridMapper.calculateStartPointPosition(ballState.startColumns[index]);
        
        return _buildBall(
          position.dx,
          position.dy,
          ballColor,
          hasBorder: true,
        );
      }),
    );
  }

  // 繪製單個終點
  Widget _buildEndPoint(BallState ballState, GridMapper gridMapper) {
    final position = gridMapper.getEndPointPosition(ballState.targetColumn);
    
    return _buildEndPointContainer(
      position.dx,
      AppTheme.kEndpointRed,
    );
  }

  // 繪製多個終點
  Widget _buildMultiEndPoints(BallState ballState, GridMapper gridMapper) {
    return Stack(
      children: List.generate(ballState.config.multiBallCount, (index) {
        Color ballColor = _getBallColor(index);
        final position = gridMapper.getEndPointPosition(ballState.endColumns[index]);
        
        return _buildEndPointContainer(
          position.dx,
          ballColor,
        );
      }),
    );
  }
  
  // 通用的終點容器渲染方法
  Widget _buildEndPointContainer(double left, Color color) {
    return Positioned(
      left: left,
      top: 0,
      child: Container(
        width: widget.cellSize,
        height: widget.cellSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withOpacity(AppTheme.kEndpointBackgroundOpacity),
          border: Border.all(
            color: color, 
            width: AppTheme.kEndpointBorderThickness,
          ),
        ),
      ),
    );
  }
  
  // 獲取不同球的顏色
  Color _getBallColor(int index) {
    final List<Color> colors = AppTheme.getBallColors();
    return colors[index % colors.length];
  }

  // 處理拖曳放置模塊的區域
  Widget _buildDropTarget(BuildContext context, BoardState boardState, BallState ballState, GridMapper gridMapper) {
    return SizedBox(
      width: ballState.config.columns * widget.cellSize,
      height: ballState.config.rows * widget.cellSize,
      child: DragTarget<ModuleType>(
        builder: (context, candidateData, rejectedData) {
          return Container(color: Colors.transparent);
        },
        onWillAccept: (data) {
          return data != null && ballState.status == GameStatus.ready;
        },
        onMove: (details) {
          if (ballState.status != GameStatus.ready) return;
          
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);
          
          final position = gridMapper.dragPositionToGrid(localPosition);
          
          if (gridMapper.isValidGridPosition(position)) {
            setState(() {
              previewPosition = position;
              previewType = details.data;
            });
          } else {
            setState(() {
              previewPosition = null;
              previewType = null;
            });
          }
        },
        onLeave: (data) {
          setState(() {
            previewPosition = null;
            previewType = null;
          });
        },
        onAccept: (type) {
          if (previewPosition != null) {
            final module = GameModule(
              type: type,
              position: previewPosition!,
            );
            
            boardState.addModule(module);
            
            setState(() {
              previewPosition = null;
              previewType = null;
            });
          }
        },
      ),
    );
  }
}

// 繪製垂直線的自定義繪圖器
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
      ..color = AppTheme.kGridLine
      ..strokeWidth = AppTheme.kGridLineThickness
      ..style = PaintingStyle.stroke;

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