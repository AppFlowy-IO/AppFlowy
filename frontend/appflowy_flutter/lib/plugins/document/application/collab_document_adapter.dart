import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/util/json_print.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';

class CollabDocumentAdapter {
  CollabDocumentAdapter(this.editorState, this.docId);

  final EditorState editorState;
  final String docId;

  final _service = DocumentService();

  /// Sync version 1
  ///
  /// Force to reload the document
  ///
  /// Only use in development
  Future<EditorState?> syncV1() async {
    final result = await _service.getDocument(viewId: docId);
    final document = result.fold((s) => s.toDocument(), (f) => null);
    if (document == null) {
      return null;
    }
    return EditorState(document: document);
  }

  /// Sync version 2
  ///
  /// Translate the [docEvent] from yrs to [Operation]s and apply it to the [editorState]
  ///
  /// Not fully implemented yet
  Future<void> syncV2(DocEventPB docEvent) async {
    prettyPrintJson(docEvent.toProto3Json());

    final transaction = editorState.transaction;

    for (final event in docEvent.events) {
      for (final blockEvent in event.event) {
        switch (blockEvent.command) {
          case DeltaTypePB.Inserted:
            break;
          case DeltaTypePB.Updated:
            await _syncUpdated(blockEvent, transaction);
            break;
          case DeltaTypePB.Removed:
            break;
          default:
        }
      }
    }

    await editorState.apply(transaction, isRemote: true);
  }

  /// Sync version 3
  ///
  /// Diff the local document with the remote document and apply the changes
  Future<void> syncV3() async {
    final result = await _service.getDocument(viewId: docId);
    final document = result.fold((s) => s.toDocument(), (f) => null);
    if (document == null) {
      return;
    }

    final ops = diffNodes(editorState.document.root, document.root);
    if (ops.isEmpty) {
      return;
    }

    final transaction = editorState.transaction;
    for (final op in ops) {
      transaction.add(op);
    }
    await editorState.apply(transaction, isRemote: true);
  }

  Future<void> _syncUpdated(
    BlockEventPayloadPB payload,
    Transaction transaction,
  ) async {
    assert(payload.command == DeltaTypePB.Updated);

    final path = payload.path;
    final id = payload.id;
    final value = jsonDecode(payload.value);

    final nodes = NodeIterator(
      document: editorState.document,
      startNode: editorState.document.root,
    ).toList();

    // 1. meta -> text_map = text delta change
    if (path.isTextDeltaChangeset) {
      // find the 'text' block and apply the delta
      // ⚠️ not completed yet.
      final target = nodes.singleWhereOrNull((n) => n.id == id);
      if (target != null) {
        try {
          final delta = Delta.fromJson(jsonDecode(value));
          transaction.insertTextDelta(target, 0, delta);
        } catch (e) {
          Log.error('Failed to apply delta: $value, error: $e');
        }
      }
    } else if (path.isBlockChangeset) {
      final target = nodes.singleWhereOrNull((n) => n.id == id);
      if (target != null) {
        try {
          final delta = jsonDecode(value['data'])['delta'];
          transaction.updateNode(target, {
            'delta': Delta.fromJson(delta).toJson(),
          });
        } catch (e) {
          Log.error('Failed to update $value, error: $e');
        }
      }
    }
  }
}

extension on List<String> {
  bool get isTextDeltaChangeset {
    return length == 3 && this[0] == 'meta' && this[1] == 'text_map';
  }

  bool get isBlockChangeset {
    return length == 2 && this[0] == 'blocks';
  }
}
