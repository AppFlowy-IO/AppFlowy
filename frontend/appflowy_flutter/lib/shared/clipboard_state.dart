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

  void didCut() {
    _isCut = true;
  }

  void didPaste() {
    _isCut = false;
  }
}
