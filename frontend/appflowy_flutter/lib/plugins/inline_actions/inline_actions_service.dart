import 'package:flutter/material.dart';

import 'package:appflowy/plugins/inline_actions/service_handler.dart';

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
  Future<void> dispose() async {
    for (final handler in handlers) {
      await handler.dispose();
    }
    context = null;
  }
}
