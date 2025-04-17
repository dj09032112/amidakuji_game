import 'package:flutter/material.dart';
import '../models/game_module.dart';
import 'module_widget.dart';

class ToolPanel extends StatelessWidget {
  final double cellSize;
  
  const ToolPanel({Key? key, required this.cellSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '模塊工具箱',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolItem(
                '橫線模塊',
                ModuleType.horizontal,
              ),
              const SizedBox(width: 12.0),
              _buildToolItem(
                '橋接模塊',
                ModuleType.bridge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(String label, ModuleType type) {
    return Column(
      children: [
        ModuleWidget.draggable(
          type: type,
          cellSize: cellSize,
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: const TextStyle(fontSize: 12.0),
        ),
      ],
    );
  }
} 