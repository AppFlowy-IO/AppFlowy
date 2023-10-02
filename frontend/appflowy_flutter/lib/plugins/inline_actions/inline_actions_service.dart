import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:flutter/material.dart';

typedef InlineActionsDelegate = Future<InlineActionsResult> Function([
  String? search,
]);

abstract class _InlineActionsProvider {
  void dispose();
}

class InlineActionsService extends _InlineActionsProvider {
  InlineActionsService({
    required this.context,
    required this.handlers,
  });

  /// The [BuildContext] in which to show the [InlineActionsMenu]
  ///
  BuildContext? context;

  final List<InlineActionsDelegate> handlers;

  /// This is a workaround for not having a mounted check.
  /// Thus when the widget that uses the service is disposed,
  /// we set the [BuildContext] to null.
  ///
  @override
  void dispose() {
    context = null;
  }
}
