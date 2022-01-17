import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class FlowyHistoryButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final bool undo;
  final QuillController controller;
  final String tooltipText;

  const FlowyHistoryButton({
    required this.icon,
    required this.controller,
    required this.undo,
    required this.tooltipText,
    required this.iconSize,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipText,
      showDuration: Duration.zero,
      child: HistoryButton(
        icon: icon,
        iconSize: iconSize,
        controller: controller,
        undo: true,
        // iconTheme: const QuillIconTheme(
        //   iconSelectedFillColor: Colors.white38,
        // ),
      ),
    );
  }
}
