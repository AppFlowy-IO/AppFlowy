import 'package:flutter/material.dart';

class SelectionWrapper extends StatefulWidget {
  const SelectionWrapper({
    super.key,
    required this.onCreate,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onCreate;
  final VoidCallback onDispose;
  final Widget child;

  @override
  State<SelectionWrapper> createState() => _SelectionWrapperState();
}

class _SelectionWrapperState extends State<SelectionWrapper> {
  @override
  Widget build(BuildContext context) {
    widget.onCreate();
    return widget.child;
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }
}
