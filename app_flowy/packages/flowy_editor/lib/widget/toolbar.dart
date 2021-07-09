import 'dart:io';

import 'package:flutter/material.dart';

/* -------------------------------- Constant -------------------------------- */

typedef OnImageSelectCallback = Future<String> Function(File file);

final double kToolbarButtonDefaultSize = 18.0;

/* --------------------------------- Toolbar -------------------------------- */

class EditorToolbar extends StatefulWidget implements PreferredSizeWidget {
  const EditorToolbar({
    required this.children,
    this.customToolbarHeight,
    this.customButtonHeight,
    Key? key,
  }) : super(key: key);

  final double? customButtonHeight;
  final double? customToolbarHeight;
  final List<Widget> children;

  @override
  Size get preferredSize {
    return Size.fromHeight(customToolbarHeight ??
        customButtonHeight ??
        kToolbarButtonDefaultSize * 2);
  }

  @override
  _EditorToolbarState createState() => _EditorToolbarState();
}

class _EditorToolbarState extends State<EditorToolbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints.tightFor(height: widget.preferredSize.height),
      color: Theme.of(context).canvasColor,
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.children,
            ),
          )
        ],
      ),
    );
  }
}
