import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'header.dart';

class AppDisclosureActionSheet
    with ActionList<DisclosureActionWrapper>, FlowyOverlayDelegate {
  final Function(dartz.Option<AppDisclosureAction>) onSelected;
  final _items = AppDisclosureAction.values
      .map((action) => DisclosureActionWrapper(action))
      .toList();

  AppDisclosureActionSheet({
    required this.onSelected,
  });

  @override
  List<DisclosureActionWrapper> get items => _items;

  @override
  void Function(dartz.Option<DisclosureActionWrapper> p1) get selectCallback =>
      (result) {
        result.fold(
          () => onSelected(dartz.none()),
          (wrapper) => onSelected(
            dartz.some(wrapper.inner),
          ),
        );
      };

  @override
  FlowyOverlayDelegate? get delegate => this;

  @override
  void didRemove() {
    onSelected(dartz.none());
  }
}

class DisclosureActionWrapper extends ActionItem {
  final AppDisclosureAction inner;

  DisclosureActionWrapper(this.inner);
  @override
  Widget? icon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.name;
}
