import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

class CocoaWindowChannel {
  CocoaWindowChannel._();

  final MethodChannel _channel = const MethodChannel("flutter/cocoaWindow");

  static final CocoaWindowChannel instance = CocoaWindowChannel._();

  Future<void> setWindowPosition(Offset offset) async {
    await _channel.invokeMethod("setWindowPosition", [offset.dx, offset.dy]);
  }

  Future<List<double>> getWindowPosition() async {
    final raw = await _channel.invokeMethod("getWindowPosition");
    final arr = raw as List<dynamic>;
    final List<double> result = arr.map((s) => s as double).toList();
    return result;
  }

  Future<void> zoom() async {
    await _channel.invokeMethod("zoom");
  }
}

class MoveWindowDetector extends StatefulWidget {
  const MoveWindowDetector({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  MoveWindowDetectorState createState() => MoveWindowDetectorState();
}

class MoveWindowDetectorState extends State<MoveWindowDetector> {
  double winX = 0;
  double winY = 0;

  @override
  Widget build(BuildContext context) {
    // the frameless window is only supported on macOS
    if (!UniversalPlatform.isMacOS) {
      return widget.child ?? const SizedBox.shrink();
    }

    // above macOS 15, we can control the window position by using system APIs
    if (ApplicationInfo.macOSMajorVersion != null &&
        ApplicationInfo.macOSMajorVersion! >= 15) {
      return widget.child ?? const SizedBox.shrink();
    }

    return GestureDetector(
      // https://stackoverflow.com/questions/52965799/flutter-gesturedetector-not-working-with-containers-in-stack
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () async => CocoaWindowChannel.instance.zoom(),
      onPanStart: (DragStartDetails details) {
        winX = details.globalPosition.dx;
        winY = details.globalPosition.dy;
      },
      onPanUpdate: (DragUpdateDetails details) async {
        final windowPos = await CocoaWindowChannel.instance.getWindowPosition();
        final double dx = windowPos[0];
        final double dy = windowPos[1];
        final deltaX = details.globalPosition.dx - winX;
        final deltaY = details.globalPosition.dy - winY;
        await CocoaWindowChannel.instance
            .setWindowPosition(Offset(dx + deltaX, dy - deltaY));
      },
      child: widget.child,
    );
  }
}
