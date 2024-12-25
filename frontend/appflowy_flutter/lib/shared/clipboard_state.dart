import 'package:flutter/foundation.dart';

/// Class to hold the state of the Clipboard.
///
/// Essentially for document in-app json paste, we need to be able
/// to differentiate between a cut-paste and a copy-paste.
///
/// When a cut-pase has occurred, the next paste operation should be
/// seen as a copy-paste.
///
class ClipboardState {
  ClipboardState();

  bool _isCut = false;

  bool get isCut => _isCut;

  final ValueNotifier<bool> isHandlingPasteNotifier = ValueNotifier(false);
  bool get isHandlingPaste => isHandlingPasteNotifier.value;

  final Set<String> _handlingPasteIds = {};

  void dispose() {
    isHandlingPasteNotifier.dispose();
  }

  void didCut() {
    _isCut = true;
  }

  void didPaste() {
    _isCut = false;
  }

  void startHandlingPaste(String id) {
    _handlingPasteIds.add(id);
    isHandlingPasteNotifier.value = true;
  }

  void endHandlingPaste(String id) {
    _handlingPasteIds.remove(id);
    if (_handlingPasteIds.isEmpty) {
      isHandlingPasteNotifier.value = false;
    }
  }
}
