import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart' hide WidgetBuilder;
import 'package:flutter/material.dart';

Future<T?> showMobileBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  ShapeBorder? shape,
  bool isDragEnabled = true,
  bool resizeToAvoidBottomInset = true,
  EdgeInsets padding = const EdgeInsets.fromLTRB(16, 16, 16, 32),
  bool showDragHandle = false,
  bool showHeader = false,
  bool showCloseButton = false,
  String title = '', // only works if showHeader is true
  Color? backgroundColor,
  bool isScrollControlled = true,
  BoxConstraints? constraints,
}) async {
  assert(() {
    if (showCloseButton || title.isNotEmpty) assert(showHeader);
    return true;
  }());

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    enableDrag: isDragEnabled,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    backgroundColor: backgroundColor,
    constraints: constraints,
    shape: shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Corners.s12Radius,
          ),
        ),
    builder: (context) {
      final List<Widget> children = [];

      if (showDragHandle) {
        children.addAll([
          const VSpace(4),
          const DragHandler(),
        ]);
      }

      if (showHeader) {
        children.addAll([
          VSpace(padding.top),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              showCloseButton
                  ? Padding(
                      padding: EdgeInsets.only(left: padding.left),
                      child: const AppBarCloseButton(
                        margin: EdgeInsets.zero,
                      ),
                    )
                  : const SizedBox.shrink(),
              FlowyText(
                title,
              ),
              showCloseButton
                  ? HSpace(padding.right + 24)
                  : const SizedBox.shrink(),
            ],
          ),
          const VSpace(4),
          const Divider(),
        ]);
      }

      final child = builder(context);

      if (resizeToAvoidBottomInset) {
        children.add(
          AnimatedPadding(
            padding: EdgeInsets.only(
              top: showHeader ? 0 : padding.top,
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
            duration: Duration.zero,
            child: child,
          ),
        );
      } else {
        children.add(child);
      }

      if (children.length == 1) {
        return children.first;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      );
    },
  );
}
