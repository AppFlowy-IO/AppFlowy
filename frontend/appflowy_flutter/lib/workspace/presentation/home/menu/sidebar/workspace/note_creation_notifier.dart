import 'package:flutter/material.dart';

/// Global notifier used to pass note-creation parameters from a deep link
/// handler to the sidebar, which has the required bloc context.
final ValueNotifier<CreateNoteParams?> createNoteNotifier =
    ValueNotifier(null);

class CreateNoteParams {
  CreateNoteParams({
    this.workspaceId,
    this.parentViewId,
    required this.name,
    this.content,
  });

  /// Target workspace UUID. If null, uses the currently open workspace.
  final String? workspaceId;

  /// Parent view (space / folder) UUID. If null, falls back to the current
  /// default space.
  final String? parentViewId;

  /// Title of the new document.
  final String name;

  /// Markdown content to pre-fill the document. May be null for an empty note.
  final String? content;
}
