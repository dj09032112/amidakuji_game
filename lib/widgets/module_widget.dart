import 'package:flutter/material.dart';
import '../models/game_module.dart';
import '../utils/grid_mapper.dart';
import '../themes/app_theme.dart';

/// 單個模塊顯示元件
class ModuleWidget extends StatelessWidget {
  final ModuleType type;
  final double width;
  final double height;
  final bool isPlaced;

  const ModuleWidget({
    Key? key,
    required this.type,
    required this.width,
    required this.height,
    this.isPlaced = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildContainer(
      child: _buildContent(),
    );
  }

  /// 包裹顏色、邊框、圓角
  Widget _buildContainer({required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.getModuleColor(type, isPlaced: isPlaced),
        borderRadius: BorderRadius.circular(AppTheme.kModuleCornerRadius),
        border: Border.all(
          color: AppTheme.kModuleBorder, 
          width: AppTheme.kModuleBorderThickness,
        ),
      ),
      child: child,
    );
  }

  /// 根據 type 建立對應內容
  Widget _buildContent() {
    switch (type) {
      case ModuleType.horizontal:
        // 縮短的水平線
        return const Center(
          child: SizedBox(
            width: 50.0,
            child: Divider(
              color: AppTheme.kModuleBorder, 
              thickness: AppTheme.kModuleContentThickness, 
              height: AppTheme.kModuleContentThickness,
            ),
          ),
        );
      case ModuleType.bridge:
        // 自訂畫筆繪製彎橋
        return Center(
          child: CustomPaint(
            size: Size(width, height),
            painter: BridgePainter(margin: 25),
          ),
        );
    }
    // 理論上不會到這裡
    return const SizedBox.shrink();
  }

  /// 快捷生成可拖放版本
  static Widget draggable({
    required ModuleType type,
    required double cellSize,
  }) {
    final gridMapper = GridMapper(
      cellSize: cellSize,
      // 這裡只是為了創建 GridMapper 實例，實際的行數列數並不影響模塊寬度計算
      rows: 10,
      columns: 10,
    );

    final w = gridMapper.getModuleWidth(type);
    final h = cellSize;

    Widget _build(bool semiTransparent) => ModuleWidget(
          type: type,
          width: w,
          height: h,
          isPlaced: false,
        );

    return Draggable<ModuleType>(
      data: type,
      feedback: _build(false),
      childWhenDragging: Opacity(
        opacity: AppTheme.kDraggingOpacity, 
        child: _build(false)
      ),
      child: _build(false),
    );
  }
}

/// 自訂橋接畫筆，margin 可調
class BridgePainter extends CustomPainter {
  final double margin;

  BridgePainter({this.margin = 25});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.kModuleBorder
      ..strokeWidth = AppTheme.kModuleContentThickness
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final ctrlX = size.width / 2;
    const controlY = 10.0;

    final path = Path()
      ..moveTo(margin, midY)
      ..quadraticBezierTo(ctrlX, controlY, size.width - margin, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BridgePainter old) =>
      old.margin != margin;
}
