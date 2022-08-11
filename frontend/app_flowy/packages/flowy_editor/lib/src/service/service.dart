import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flowy_editor/src/service/render_plugin_service.dart';
import 'package:flowy_editor/src/service/scroll_service.dart';
import 'package:flowy_editor/src/service/selection_service.dart';
import 'package:flowy_editor/src/service/toolbar_service.dart';
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
  FlowyKeyboardService? get keyboardService {
    if (keyboardServiceKey.currentState != null &&
        keyboardServiceKey.currentState is FlowyKeyboardService) {
      return keyboardServiceKey.currentState! as FlowyKeyboardService;
    }
    return null;
  }

  // input service
  final inputServiceKey = GlobalKey(debugLabel: 'flowy_input_service');

  // render plugin service
  late FlowyRenderPlugin renderPluginService;

  // toolbar service
  final toolbarServiceKey = GlobalKey(debugLabel: 'flowy_toolbar_service');
  FlowyToolbarService? get toolbarService {
    if (toolbarServiceKey.currentState != null &&
        toolbarServiceKey.currentState is FlowyToolbarService) {
      return toolbarServiceKey.currentState! as FlowyToolbarService;
    }
    return null;
  }

  // scroll service
  final scrollServiceKey = GlobalKey(debugLabel: 'flowy_scroll_service');
  FlowyScrollService? get scrollService {
    if (scrollServiceKey.currentState != null &&
        scrollServiceKey.currentState is FlowyScrollService) {
      return scrollServiceKey.currentState! as FlowyScrollService;
    }
    return null;
  }
}
