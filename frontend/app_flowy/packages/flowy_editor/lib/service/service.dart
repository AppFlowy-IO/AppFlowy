import 'package:flowy_editor/service/render_plugin_service.dart';
import 'package:flowy_editor/service/toolbar_service.dart';
import 'package:flowy_editor/service/selection_service.dart';
import 'package:flutter/material.dart';

class FlowyService {
  // selection service
  final selectionServiceKey = GlobalKey(debugLabel: 'flowy_selection_service');
  FlowySelectionService get selectionService {
    assert(selectionServiceKey.currentState != null &&
        selectionServiceKey.currentState is FlowySelectionService);
    return selectionServiceKey.currentState! as FlowySelectionService;
  }

  // keyboard service
  final keyboardServiceKey = GlobalKey(debugLabel: 'flowy_keyboard_service');

  // input service
  final inputServiceKey = GlobalKey(debugLabel: 'flowy_input_service');

  // render plugin service
  late FlowyRenderPlugin renderPluginService;

  // toolbar service
  final toolbarServiceKey = GlobalKey(debugLabel: 'flowy_toolbar_service');
  ToolbarService? get toolbarService {
    if (toolbarServiceKey.currentState != null &&
        toolbarServiceKey.currentState is ToolbarService) {
      return toolbarServiceKey.currentState! as ToolbarService;
    }
    return null;
  }
}
