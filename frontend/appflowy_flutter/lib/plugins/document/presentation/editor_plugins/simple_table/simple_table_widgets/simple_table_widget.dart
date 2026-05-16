import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import '_desktop_simple_table_widget.dart';
import '_mobile_simple_table_widget.dart';

class SimpleTableWidget extends StatefulWidget {
  const SimpleTableWidget({
    super.key,
    required this.simpleTableContext,
    required this.node,
    this.enableAddColumnButton = true,
    this.enableAddRowButton = true,
    this.enableAddColumnAndRowButton = true,
    this.enableHoverEffect = true,
    this.isFeedback = false,
    this.alwaysDistributeColumnWidths = false,
  });

  /// The node of the table.
  ///
  /// Its type must be [SimpleTableBlockKeys.type].
  final Node node;

  /// The context of the simple table.
  final SimpleTableContext simpleTableContext;

  /// Whether to show the add column button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddColumnButton;

  /// Whether to show the add row button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddRowButton;

  /// Whether to show the add column and row button.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableAddColumnAndRowButton;

  /// Whether to enable the hover effect.
  ///
  /// For the feedback widget builder, it should be false.
  final bool enableHoverEffect;

  /// Whether the widget is a feedback widget.
  final bool isFeedback;

  /// Whether the columns should ignore their widths and fill available space
  final bool alwaysDistributeColumnWidths;

  @override
  State<SimpleTableWidget> createState() => _SimpleTableWidgetState();
}

class _SimpleTableWidgetState extends State<SimpleTableWidget> {
  @override
  Widget build(BuildContext context) {
    return UniversalPlatform.isDesktop
        ? DesktopSimpleTableWidget(
            simpleTableContext: widget.simpleTableContext,
            node: widget.node,
            enableAddColumnButton: widget.enableAddColumnButton,
            enableAddRowButton: widget.enableAddRowButton,
            enableAddColumnAndRowButton: widget.enableAddColumnAndRowButton,
            enableHoverEffect: widget.enableHoverEffect,
            isFeedback: widget.isFeedback,
            alwaysDistributeColumnWidths: widget.alwaysDistributeColumnWidths,
          )
        : MobileSimpleTableWidget(
            simpleTableContext: widget.simpleTableContext,
            node: widget.node,
            enableAddColumnButton: widget.enableAddColumnButton,
            enableAddRowButton: widget.enableAddRowButton,
            enableAddColumnAndRowButton: widget.enableAddColumnAndRowButton,
            enableHoverEffect: widget.enableHoverEffect,
            isFeedback: widget.isFeedback,
            alwaysDistributeColumnWidths: widget.alwaysDistributeColumnWidths,
          );
  }
}
