import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/diff_delta.dart';
import '../editor.dart';

mixin RawEditorStateTextInputClientMixin on EditorState
    implements TextInputClient {
  final List<TextEditingValue> _sentRemoteValues = [];
  TextInputConnection? _textInputConnection;
  TextEditingValue? _lastKnownRemoteTextEditingValue;

  /// Whether to create an input connection with the platform for text editing
  /// or not.
  ///
  /// Read-only input fields do not need a connection with the platform since
  /// there's no need for text editing capabilities (e.g. virtual keyboard).
  ///
  /// On the web, we always need a connection because we want some browser
  /// functionalities to continue to work on read-only input fields like:
  ///
  /// - Relevant context menu.
  /// - cmd/ctrl+c shortcut to copy.
  /// - cmd/ctrl+a to select all.
  /// - Changing the selection using a physical keyboard.
  bool get shouldCreateInputConnection => kIsWeb || !widget.readOnly;

  /// Returns `true` if there is open input connection.
  bool get hasConnection =>
      _textInputConnection != null && _textInputConnection!.attached;

  /// Opens or closes input connection based on the current state of
  /// [focusNode] and [value].
  void openOrCloseConnection() {
    if (widget.focusNode.hasFocus && widget.focusNode.consumeKeyboardToken()) {
      openConnectionIfNeeded();
    } else if (!widget.focusNode.hasFocus) {
      closeConnectionIfNeeded();
    }
  }

  void openConnectionIfNeeded() {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (!hasConnection) {
      _lastKnownRemoteTextEditingValue = getTextEditingValue();
      _textInputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          inputType: TextInputType.multiline,
          readOnly: widget.readOnly,
          inputAction: TextInputAction.newline,
          enableSuggestions: !widget.readOnly,
          keyboardAppearance: widget.keyboardAppearance,
          textCapitalization: widget.textCapitalization,
        ),
      );

      _textInputConnection!.setEditingState(_lastKnownRemoteTextEditingValue!);
      // _sentRemoteValues.add(_lastKnownRemoteTextEditingValue);
    }

    _textInputConnection!.show();
  }

  /// Closes input connection if it's currently open. Otherwise does nothing.
  void closeConnectionIfNeeded() {
    if (!hasConnection) {
      return;
    }
    _textInputConnection!.close();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
    _sentRemoteValues.clear();
  }

  /// Updates remote value based on current state of [document] and
  /// [selection].
  ///
  /// This method may not actually send an update to native side if it thinks
  /// remote value is up to date or identical.
  void updateRemoteValueIfNeeded() {
    if (!hasConnection) {
      return;
    }

    // Since we don't keep track of the composing range in value provided
    // by the Controller we need to add it here manually before comparing
    // with the last known remote value.
    // It is important to prevent excessive remote updates as it can cause
    // race conditions.
    final actualValue = getTextEditingValue().copyWith(
      composing: _lastKnownRemoteTextEditingValue!.composing,
    );

    if (actualValue == _lastKnownRemoteTextEditingValue) {
      return;
    }

    final shouldRemember =
        getTextEditingValue().text != _lastKnownRemoteTextEditingValue!.text;
    _lastKnownRemoteTextEditingValue = actualValue;
    _textInputConnection!.setEditingState(
      // Set composing to (-1, -1), otherwise an exception will be thrown if
      // the values are different.
      actualValue.copyWith(composing: const TextRange(start: -1, end: -1)),
    );
    if (shouldRemember) {
      // Only keep track if text changed (selection changes are not relevant)
      _sentRemoteValues.add(actualValue);
    }
  }

  @override
  TextEditingValue? get currentTextEditingValue =>
      _lastKnownRemoteTextEditingValue;

  // autofill is not needed
  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    if (!shouldCreateInputConnection) {
      return;
    }

    if (_sentRemoteValues.contains(value)) {
      /// There is a race condition in Flutter text input plugin where sending
      /// updates to native side too often results in broken behavior.
      /// TextInputConnection.setEditingValue is an async call to native side.
      /// For each such call native side _always_ sends an update which triggers
      /// this method (updateEditingValue) with the same value we've sent it.
      /// If multiple calls to setEditingValue happen too fast and we only
      /// track the last sent value then there is no way for us to filter out
      /// automatic callbacks from native side.
      /// Therefore we have to keep track of all values we send to the native
      /// side and when we see this same value appear here we skip it.
      /// This is fragile but it's probably the only available option.
      _sentRemoteValues.remove(value);
      return;
    }

    if (_lastKnownRemoteTextEditingValue == value) {
      // There is no difference between this value and the last known value.
      return;
    }

    // Check if only composing range changed.
    if (_lastKnownRemoteTextEditingValue!.text == value.text &&
        _lastKnownRemoteTextEditingValue!.selection == value.selection) {
      // This update only modifies composing range. Since we don't keep track
      // of composing range we just need to update last known value here.
      // This check fixes an issue on Android when it sends
      // composing updates separately from regular changes for text and
      // selection.
      _lastKnownRemoteTextEditingValue = value;
      return;
    }

    final effectiveLastKnownValue = _lastKnownRemoteTextEditingValue!;
    _lastKnownRemoteTextEditingValue = value;
    final oldText = effectiveLastKnownValue.text;
    final text = value.text;
    final cursorPosition = value.selection.extentOffset;
    final diff = getDiff(oldText, text, cursorPosition);
    widget.controller.replaceText(
        diff.start, diff.deleted.length, diff.inserted, value.selection);
  }

  @override
  void performAction(TextInputAction action) {
    // no-op
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // no-op
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    throw UnimplementedError();
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    throw UnimplementedError();
  }

  @override
  void connectionClosed() {
    if (!hasConnection) {
      return;
    }
    _textInputConnection!.connectionClosedReceived();
    _textInputConnection = null;
    _lastKnownRemoteTextEditingValue = null;
    _sentRemoteValues.clear();
  }
}
