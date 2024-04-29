import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_awareness_metadata.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/shared/list_extension.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/util/color_generator/color_generator.dart';
import 'package:appflowy/util/json_print.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DocumentCollabAdapter {
  DocumentCollabAdapter(this.editorState, this.docId);

  final EditorState editorState;
  final String docId;

  final _service = DocumentService();

  /// Sync version 1
  ///
  /// Force to reload the document
  ///
  /// Only use in development
  Future<EditorState?> syncV1() async {
    final result = await _service.getDocument(documentId: docId);
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
  Future<void> syncV3({DocEventPB? docEvent}) async {
    final result = await _service.getDocument(documentId: docId);
    final document = result.fold((s) => s.toDocument(), (f) => null);
    if (document == null) {
      return;
    }

    final ops = diffNodes(editorState.document.root, document.root);
    if (ops.isEmpty) {
      return;
    }

    // Use for debugging, DO NOT REMOVE
    // prettyPrintJson(ops.map((op) => op.toJson()).toList());

    final transaction = editorState.transaction;
    for (final op in ops) {
      transaction.add(op);
    }
    await editorState.apply(transaction, isRemote: true);

    // Use for debugging, DO NOT REMOVE
    // assert(() {
    //   final local = editorState.document.root.toJson();
    //   final remote = document.root.toJson();
    //   if (!const DeepCollectionEquality().equals(local, remote)) {
    //     Log.error('Invalid diff status');
    //     Log.error('Local: $local');
    //     Log.error('Remote: $remote');
    //     return false;
    //   }
    //   return true;
    // }());
  }

  Future<void> forceReload() async {
    final result = await _service.getDocument(documentId: docId);
    final document = result.fold((s) => s.toDocument(), (f) => null);
    if (document == null) {
      return;
    }

    final beforeSelection = editorState.selection;

    final clear = editorState.transaction;
    clear.deleteNodes(editorState.document.root.children);
    await editorState.apply(clear, isRemote: true);

    final insert = editorState.transaction;
    insert.insertNodes([0], document.root.children);
    await editorState.apply(insert, isRemote: true);

    editorState.selection = beforeSelection;
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

  Future<void> updateRemoteSelection(
    String userId,
    DocumentAwarenessStatesPB states,
  ) async {
    final List<RemoteSelection> remoteSelections = [];
    final deviceId = ApplicationInfo.deviceId;
    // the values may be duplicated, sort by the timestamp and then filter the duplicated values
    final values = states.value.values
        .sorted(
          (a, b) => b.timestamp.compareTo(a.timestamp),
        ) // in descending order
        .unique(
          (e) => Object.hashAll([e.user.uid, e.user.deviceId]),
        );
    for (final state in values) {
      // the following code is only for version 1
      if (state.version != 1) {
        return;
      }
      final uid = state.user.uid.toString();
      final did = state.user.deviceId;
      final metadata = DocumentAwarenessMetadata.fromJson(
        jsonDecode(state.metadata),
      );
      final selectionColor = metadata.selectionColor.tryToColor();
      final cursorColor = metadata.cursorColor.tryToColor();
      if ((uid == userId && did == deviceId) ||
          (cursorColor == null || selectionColor == null)) {
        continue;
      }
      final start = state.selection.start;
      final end = state.selection.end;
      final selection = Selection(
        start: Position(
          path: start.path.toIntList(),
          offset: start.offset.toInt(),
        ),
        end: Position(
          path: end.path.toIntList(),
          offset: end.offset.toInt(),
        ),
      );
      final color = ColorGenerator(uid + did).toColor();
      final remoteSelection = RemoteSelection(
        id: uid,
        selection: selection,
        selectionColor: selectionColor,
        cursorColor: cursorColor,
        builder: (_, __, rect) {
          return Positioned(
            top: rect.top - 14,
            left: selection.isCollapsed ? rect.right : rect.left,
            child: ColoredBox(
              color: color,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                  vertical: 1.0,
                ),
                child: FlowyText(
                  metadata.userName,
                  color: Colors.black,
                  fontSize: 12.0,
                ),
              ),
            ),
          );
        },
      );
      remoteSelections.add(remoteSelection);
    }
    if (remoteSelections.isNotEmpty) {
      editorState.remoteSelections.value = remoteSelections;
    }
  }
}

extension on List<Int64> {
  List<int> toIntList() {
    return map((e) => e.toInt()).toList();
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
