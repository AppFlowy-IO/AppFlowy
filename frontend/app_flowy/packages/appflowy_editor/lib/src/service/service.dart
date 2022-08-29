import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/service/toolbar_service.dart';
import 'package:flutter/material.dart';

class FlowyService {
  // selection service
  final selectionServiceKey = GlobalKey(debugLabel: 'flowy_selection_service');
  AppFlowySelectionService get selectionService {
    assert(selectionServiceKey.currentState != null &&
        selectionServiceKey.currentState is AppFlowySelectionService);
    return selectionServiceKey.currentState! as AppFlowySelectionService;
  }

  // keyboard service
  final keyboardServiceKey = GlobalKey(debugLabel: 'flowy_keyboard_service');
  AppFlowyKeyboardService? get keyboardService {
    if (keyboardServiceKey.currentState != null &&
        keyboardServiceKey.currentState is AppFlowyKeyboardService) {
      return keyboardServiceKey.currentState! as AppFlowyKeyboardService;
    }
    return null;
  }

  // input service
  final inputServiceKey = GlobalKey(debugLabel: 'flowy_input_service');
  AppFlowyInputService? get inputService {
    if (inputServiceKey.currentState != null &&
        inputServiceKey.currentState is AppFlowyInputService) {
      return inputServiceKey.currentState! as AppFlowyInputService;
    }
    return null;
  }

  // render plugin service
  late AppFlowyRenderPlugin renderPluginService;

  // toolbar service
  final toolbarServiceKey = GlobalKey(debugLabel: 'flowy_toolbar_service');
  AppFlowyToolbarService? get toolbarService {
    if (toolbarServiceKey.currentState != null &&
        toolbarServiceKey.currentState is AppFlowyToolbarService) {
      return toolbarServiceKey.currentState! as AppFlowyToolbarService;
    }
    return null;
  }

  // scroll service
  final scrollServiceKey = GlobalKey(debugLabel: 'flowy_scroll_service');
  AppFlowyScrollService? get scrollService {
    if (scrollServiceKey.currentState != null &&
        scrollServiceKey.currentState is AppFlowyScrollService) {
      return scrollServiceKey.currentState! as AppFlowyScrollService;
    }
    return null;
  }
}
