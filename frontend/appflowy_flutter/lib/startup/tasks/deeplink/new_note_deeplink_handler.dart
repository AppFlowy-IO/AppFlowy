import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/note_creation_notifier.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/services.dart';

/// Handles deep links of the form:
///
/// ```
/// appflowy-flutter://new
///   ?workspace_id=<uuid>          (optional – switches workspace first)
///   &parent_view_id=<uuid>        (optional – target space / folder)
///   &name=<title>                 (optional – defaults to "New Note")
///   &content=<url-encoded-markdown>  (optional)
///   &clipboard                    (optional – read content from clipboard)
/// ```
///
/// Either `content` or `clipboard` can supply the initial Markdown body.
/// If both are present, `clipboard` takes precedence.
class NewNoteDeepLinkHandler extends DeepLinkHandler<void> {
  static const _host = 'new';
  static const _workspaceIdKey = 'workspace_id';
  static const _parentViewIdKey = 'parent_view_id';
  static const _nameKey = 'name';
  static const _contentKey = 'content';
  static const _clipboardKey = 'clipboard';

  @override
  bool canHandle(Uri uri) => uri.host == _host;

  @override
  Future<FlowyResult<void, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    final name = uri.queryParameters[_nameKey]?.trim();
    final effectiveName =
        (name == null || name.isEmpty) ? 'New Note' : name;

    String? content;

    // `clipboard` flag takes precedence over an explicit `content` value.
    if (uri.queryParameters.containsKey(_clipboardKey)) {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      content = clipboardData?.text;
      if (content == null || content.isEmpty) {
        Log.warn('NewNoteDeepLink: clipboard was empty');
      }
    } else {
      content = uri.queryParameters[_contentKey];
    }

    createNoteNotifier.value = CreateNoteParams(
      workspaceId: uri.queryParameters[_workspaceIdKey],
      parentViewId: uri.queryParameters[_parentViewIdKey],
      name: effectiveName,
      content: content,
    );

    Log.info(
      'NewNoteDeepLink: queued note creation '
      '"$effectiveName" (workspace=${uri.queryParameters[_workspaceIdKey]}, '
      'parent=${uri.queryParameters[_parentViewIdKey]})',
    );

    return FlowyResult.success(null);
  }
}
