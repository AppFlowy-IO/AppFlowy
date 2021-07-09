import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

import '../model/document/node/leaf.dart';
import '../widget/raw_editor.dart';
import '../widget/selection.dart';
import '../rendering/editor.dart';

/* ----------------------- Selection Gesture Detector ----------------------- */

abstract class EditorTextSelectionGestureDetectorBuilderDelegate {
  GlobalKey<EditorState> getEditableTextKey();

  bool getForcePressEnabled();

  bool getSelectionEnabled();
}

class EditorTextSelectionGestureDetectorBuilder {
  EditorTextSelectionGestureDetectorBuilder(this.delegate);

  final EditorTextSelectionGestureDetectorBuilderDelegate delegate;
  bool shouldShowSelectionToolbar = true;

  EditorState? getEditor() {
    return delegate.getEditableTextKey().currentState;
  }

  RenderEditor? getRenderEditor() {
    return getEditor()!.getRenderEditor();
  }

  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.getForcePressEnabled());
    shouldShowSelectionToolbar = true;
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWordsInRange(
        details.globalPosition,
        null,
        SelectionChangedCause.forcePress,
      );
    }
  }

  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.getForcePressEnabled());
    getRenderEditor()!.selectWordsInRange(
      details.globalPosition,
      null,
      SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  void onTapDown(TapDownDetails details) {
    getRenderEditor()!.handleTapDown(details);

    final kind = details.kind;
    shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  void onTapUp(TapUpDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWordEdge(SelectionChangedCause.tap);
    }
  }

  void onTapCancel() {}

  void onLongPressStart(LongPressStartDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectPositionAt(
        details.globalPosition,
        null,
        SelectionChangedCause.longPress,
      );
    }
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectPositionAt(
        details.globalPosition,
        null,
        SelectionChangedCause.longPress,
      );
    }
  }

  void onLongPressEnd(LongPressEndDetails details) {
    if (shouldShowSelectionToolbar) {
      getEditor()!.showToolbar();
    }
  }

  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.getSelectionEnabled()) {
      getRenderEditor()!.selectWord(SelectionChangedCause.tap);
      if (shouldShowSelectionToolbar) {
        getEditor()!.showToolbar();
      }
    }
  }

  void onDragSelectionStart(DragStartDetails details) {
    getRenderEditor()!.selectPositionAt(
      details.globalPosition,
      null,
      SelectionChangedCause.drag,
    );
  }

  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    getRenderEditor()!.selectPositionAt(
      startDetails.globalPosition,
      updateDetails.globalPosition,
      SelectionChangedCause.drag,
    );
  }

  void onDragSelectionEnd(DragEndDetails details) {}

  Widget build(HitTestBehavior behavior, Widget child) {
    return EditorTextSelectionGestureDetector(
      onTapUp: onTapUp,
      onTapDown: onTapDown,
      onTapCancel: onTapCancel,
      onForcePressStart:
          delegate.getForcePressEnabled() ? onForcePressStart : null,
      onForcePressEnd: delegate.getForcePressEnabled() ? onForcePressEnd : null,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }
}

/* ---------------------------------- Embed --------------------------------- */

class EmbedBuilder {
  static const kImageTypeKey = 'image';
  static const kVideoTypeKey = 'video';

  static Widget defaultBuilder(BuildContext context, Embed node) {
    assert(!kIsWeb, 'Please provide EmbedBuilder for Web');
    switch (node.value.type) {
      case kImageTypeKey:
        return _generateImageEmbed(context, node);
      default:
        throw UnimplementedError(
            'Embeddable type "${node.value.type}" is not supported by default embed '
            'builder of QuillEditor. You must pass your own builder function to '
            'embedBuilder property of QuillEditor or QuillField widgets.');
    }
  }

  // Generator

  static Widget _generateImageEmbed(BuildContext context, Embed node) {
    final imageUrl = standardizeImageUrl(node.value.data);
    return imageUrl.startsWith('http')
        ? Image.network(imageUrl)
        : isBase64(imageUrl)
            ? Image.memory(base64.decode(imageUrl))
            : Image.file(io.File(imageUrl));
  }

  // Helper

  static String standardizeImageUrl(String url) {
    if (url.contains('base64')) {
      return url.split(',')[1];
    }
    return url;
  }
}
