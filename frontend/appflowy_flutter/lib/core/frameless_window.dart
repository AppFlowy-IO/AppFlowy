import 'package:flutter/material.dart';

import 'package:window_manager/window_manager.dart';

class MoveWindowDetector extends StatefulWidget {
  const MoveWindowDetector({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  MoveWindowDetectorState createState() => MoveWindowDetectorState();
}

class MoveWindowDetectorState extends State<MoveWindowDetector> {
  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(child: widget.child ?? Container());
  }
}
