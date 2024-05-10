import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

class WindowsButtonListener extends WindowListener {
  WindowsButtonListener();

  final ValueNotifier<bool> isMaximized = ValueNotifier(false);

  @override
  void onWindowMaximize() {
    isMaximized.value = true;
  }

  @override
  void onWindowUnmaximize() {
    isMaximized.value = false;
  }

  void dispose() {
    isMaximized.dispose();
  }
}

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
    this.showTitleBar = false,
  });

  final Widget? child;
  final bool showTitleBar;

  @override
  MoveWindowDetectorState createState() => MoveWindowDetectorState();
}

class MoveWindowDetectorState extends State<MoveWindowDetector> {
  late final WindowsButtonListener? windowsButtonListener;

  double winX = 0;
  double winY = 0;

  bool isMaximized = false;

  @override
  void initState() {
    if (PlatformExtension.isWindows) {
      windowsButtonListener = WindowsButtonListener();
      windowManager.addListener(windowsButtonListener!);
      windowsButtonListener!.isMaximized.addListener(() {
        if (mounted) {
          setState(
            () => isMaximized = windowsButtonListener!.isMaximized.value,
          );
        }
      });
    } else {
      windowsButtonListener = null;
    }

    windowManager.isMaximized().then(
          (v) => mounted ? setState(() => isMaximized = v) : null,
        );
    super.initState();
  }

  @override
  void dispose() {
    if (windowsButtonListener != null) {
      windowManager.removeListener(windowsButtonListener!);
      windowsButtonListener?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS && !Platform.isWindows) {
      return widget.child ?? const SizedBox.shrink();
    }

    if (Platform.isWindows) {
      final brightness = Theme.of(context).brightness;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitleBar) ...[
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: DragToMoveArea(
                child: Row(
                  children: [
                    const HSpace(4),
                    _buildToggleMenuButton(context),
                    const Spacer(),
                    WindowCaptionButton.minimize(
                      brightness: brightness,
                      onPressed: () => windowManager.minimize(),
                    ),
                    if (isMaximized) ...[
                      WindowCaptionButton.unmaximize(
                        brightness: brightness,
                        onPressed: () => windowManager.unmaximize(),
                      ),
                    ] else ...[
                      WindowCaptionButton.maximize(
                        brightness: brightness,
                        onPressed: () => windowManager.maximize(),
                      ),
                    ],
                    WindowCaptionButton.close(
                      brightness: brightness,
                      onPressed: () => windowManager.close(),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 5),
          ],
          widget.child ?? const SizedBox.shrink(),
        ],
      );
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

  Widget _buildToggleMenuButton(BuildContext context) {
    if (!context.read<HomeSettingBloc>().state.isMenuCollapsed) {
      return const SizedBox.shrink();
    }

    return FlowyTooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(text: '${LocaleKeys.sideBar_closeSidebar.tr()}\n'),
          const TextSpan(text: 'Ctrl+\\'),
        ],
      ),
      child: FlowyIconButton(
        hoverColor: Colors.transparent,
        onPressed: () => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.collapseMenu()),
        iconPadding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        icon: context.read<HomeSettingBloc>().state.isMenuCollapsed
            ? const FlowySvg(FlowySvgs.show_menu_s)
            : const FlowySvg(FlowySvgs.hide_menu_m),
      ),
    );
  }
}
