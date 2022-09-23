import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/theme.dart';
import 'package:provider/provider.dart';

import 'item.dart';

// [[Widget: LifeCycle]]
// https://flutterbyexample.com/lesson/stateful-widget-lifecycle
class ViewDisclosureButton extends StatelessWidget
    with ActionList<ViewDisclosureActionWrapper>, FlowyOverlayDelegate {
  final Function() onTap;
  final Function(dartz.Option<ViewDisclosureAction>) onSelected;
  final _items = ViewDisclosureAction.values
      .map((action) => ViewDisclosureActionWrapper(action))
      .toList();

  ViewDisclosureButton({
    Key? key,
    required this.onTap,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyIconButton(
      iconPadding: const EdgeInsets.all(5),
      width: 26,
      onPressed: () {
        onTap();
        show(context);
      },
      icon: svgWidget("editor/details", color: theme.iconColor),
    );
  }

  @override
  List<ViewDisclosureActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<ViewDisclosureActionWrapper> p1)
      get selectCallback => (result) {
            result.fold(
              () => onSelected(dartz.none()),
              (wrapper) => onSelected(dartz.some(wrapper.inner)),
            );
          };

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  void didRemove() {
    onSelected(dartz.none());
  }
}

class ViewDisclosureRegion extends StatelessWidget
    with ActionList<ViewDisclosureActionWrapper>, FlowyOverlayDelegate {
  final Widget child;
  final Function() onTap;
  final Function(dartz.Option<ViewDisclosureAction>) onSelected;
  final _items = ViewDisclosureAction.values
      .map((action) => ViewDisclosureActionWrapper(action))
      .toList();

  ViewDisclosureRegion(
      {Key? key,
      required this.onSelected,
      required this.onTap,
      required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => _handleClick(event, context),
      child: child,
    );
  }

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  List<ViewDisclosureActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<ViewDisclosureActionWrapper> p1)
      get selectCallback => (result) {
            result.fold(
              () => onSelected(dartz.none()),
              (wrapper) => onSelected(dartz.some(wrapper.inner)),
            );
          };

  @override
  void didRemove() {
    onSelected(dartz.none());
  }

  void _handleClick(PointerDownEvent event, BuildContext context) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kSecondaryMouseButton) {
      RenderBox box = context.findRenderObject() as RenderBox;
      Offset position = box.localToGlobal(Offset.zero);
      double x = event.position.dx - position.dx - box.size.width;
      double y = event.position.dy - position.dy - box.size.height;
      onTap();
      show(context, anchorOffset: Offset(x, y));
    }
  }
}

class ViewDisclosureActionWrapper extends ActionItem {
  final ViewDisclosureAction inner;

  ViewDisclosureActionWrapper(this.inner);
  @override
  Widget? icon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.name;
}
