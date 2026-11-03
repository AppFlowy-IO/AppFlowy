import 'package:flutter/foundation.dart';

/// Parameters for a note-creation deep-link request.
class CreateNoteParams {
  CreateNoteParams({
    this.workspaceId,
    this.parentViewId,
    required this.name,
    this.content,
  });

  /// Target workspace UUID. If null, the currently open workspace is used.
  final String? workspaceId;

  /// Parent view (space / folder) UUID. If null, falls back to the current
  /// default space.
  final String? parentViewId;

  /// Title of the new document.
  final String name;

  /// Markdown content to pre-fill the document. May be null for an empty note.
  final String? content;
}

/// Service registered in [getIt] that carries a pending note-creation request
/// from the deep-link layer to the sidebar layer.
///
/// Using a [ChangeNotifier]-based singleton registered via [getIt] avoids
/// leaking a hidden global mutable across layers and makes the dependency
/// explicit and injectable for tests.
class CreateNoteService extends ChangeNotifier {
  CreateNoteParams? _pending;

  /// The pending note-creation request, or null when idle.
  CreateNoteParams? get pending => _pending;

  /// Enqueue a new note-creation request and notify listeners.
  void request(CreateNoteParams params) {
    _pending = params;
    notifyListeners();
  }

  /// Mark the pending request as handled (consume it).
  void consume() {
    _pending = null;
  }
}
