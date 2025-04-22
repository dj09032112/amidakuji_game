import 'package:flutter/material.dart';
import '../models/game_module.dart';
import '../themes/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'module_widget.dart';

class ToolPanel extends StatelessWidget {
  final double cellSize;
  
  const ToolPanel({Key? key, required this.cellSize}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    return Container(
      padding: AppTheme.kToolboxPadding,
      decoration: BoxDecoration(
        color: AppTheme.kToolboxBackground,
        borderRadius: BorderRadius.circular(AppTheme.kToolboxCornerRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kToolboxShadow,
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.toolboxTitle,
            style: AppTheme.kToolboxTitleStyle,
          ),
          SizedBox(height: AppTheme.kToolboxSpacing),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolItem(
                context,
                localizations.horizontalModule,
                ModuleType.horizontal,
              ),
              SizedBox(width: AppTheme.kToolItemMargin),
              _buildToolItem(
                context,
                localizations.bridgeModule,
                ModuleType.bridge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem(BuildContext context, String label, ModuleType type) {
    return Column(
      children: [
        ModuleWidget.draggable(
          type: type,
          cellSize: cellSize,
        ),
        SizedBox(height: AppTheme.kToolItemSpacing),
        Text(
          label,
          style: AppTheme.kToolboxLabelStyle,
        ),
      ],
    );
  }
} 