import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/window_title_bar.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  double winX = 0;
  double winY = 0;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS && !Platform.isWindows) {
      return widget.child ?? const SizedBox.shrink();
    }

    if (Platform.isWindows) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showTitleBar) ...[
            WindowTitleBar(
              leftChildren: [
                _buildToggleMenuButton(context),
              ],
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
