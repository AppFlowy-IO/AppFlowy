import 'package:flutter/material.dart';

import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

import 'item.dart';

// [[Widget: LifeCycle]]
// https://flutterbyexample.com/lesson/stateful-widget-lifecycle
class ViewDisclosureButton extends StatelessWidget
    with ActionList<ViewDisclosureActionWrapper>
    implements FlowyOverlayDelegate {
  final Function() onTap;
  final Function(dartz.Option<ViewDisclosureAction>) onSelected;
  final _items = ViewDisclosureAction.values.map((action) => ViewDisclosureActionWrapper(action)).toList();

  ViewDisclosureButton({
    Key? key,
    required this.onTap,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      iconPadding: const EdgeInsets.all(5),
      width: 26,
      onPressed: () {
        onTap();
        show(context, context);
      },
      icon: svg("editor/details", color: Theme.of(context).iconTheme.color),
    );
  }

  @override
  List<ViewDisclosureActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<ViewDisclosureActionWrapper> p1) get selectCallback => (result) {
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

class ViewDisclosureActionWrapper extends ActionItem {
  final ViewDisclosureAction inner;

  ViewDisclosureActionWrapper(this.inner);
  @override
  Widget? get icon => inner.icon;

  @override
  String get name => inner.name;
}
