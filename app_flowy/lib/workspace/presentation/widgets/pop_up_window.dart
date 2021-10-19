import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

class FlowyPoppuWindow extends StatelessWidget {
  final Widget child;
  const FlowyPoppuWindow({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static Future<void> show(
    BuildContext context, {
    required Widget child,
  }) async {
    final window = await getWindowInfo();
    FlowyOverlay.of(context).insertWithRect(
      widget: FlowyPoppuWindow(child: child),
      identifier: 'FlowyPoppuWindow',
      anchorPosition: Offset.zero,
      anchorSize: window.frame.size,
      anchorDirection: AnchorDirection.center,
      style: FlowyOverlayStyle(blur: true),
    );
  }
}
