import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_listener.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_page_bloc.freezed.dart';

typedef MentionPageStatus = (ViewPB? view, bool isInTrash, bool isDeleted);

/// Observer the mentioned page status
/// Including:
/// - if view is changed, title, icon
/// - if view is in trash
/// - if view is deleted
/// if the block id is not null
/// - if block content is changed
/// - if the block is deleted
class MentionPageBloc extends Bloc<MentionPageEvent, MentionPageState> {
  MentionPageBloc({
    required this.pageId,
    this.blockId,
  }) : super(MentionPageState.initial()) {
    on<MentionPageEvent>((event, emit) async {
      await event.when(
        initial: () async {
          final (view, isInTrash, isDeleted) = await _fetchView(pageId);
          final blockContent = await _fetchBlockContent();
          emit(
            state.copyWith(
              view: view,
              blockContent: blockContent ?? '',
              isLoading: false,
              isInTrash: isInTrash,
              isDeleted: isDeleted,
            ),
          );

          if (view != null) {
            _startListeningView();
            // this function is time-consuming, don't block the doc rendering
            unawaited(_startListeningDocument());
          }
        },
        didUpdateBlockContent: (content) {
          emit(
            state.copyWith(
              blockContent: content,
            ),
          );
        },
        didUpdateViewStatus: (mentionPageStatus) {
          emit(
            state.copyWith(
              view: mentionPageStatus.$1,
              isInTrash: mentionPageStatus.$2,
              isDeleted: mentionPageStatus.$3,
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() {
    _viewListener?.stop();
    _documentListener?.stop();
    return super.close();
  }

  final String pageId;
  final String? blockId;

  final _documentService = DocumentService();
  ViewListener? _viewListener;
  DocumentListener? _documentListener;
  BlockPB? _block;
  String? _blockTextId;
  Delta? _initialDelta;

  void _startListeningView() {
    _viewListener = ViewListener(viewId: pageId)
      ..start(
        onViewUpdated: (view) {
          add(
            MentionPageEvent.didUpdateViewStatus(
              (view, false, false),
            ),
          );
        },
        onViewMoveToTrash: (view) {
          add(
            MentionPageEvent.didUpdateViewStatus(
              (state.view, true, false),
            ),
          );
        },
        onViewDeleted: (view) {
          add(
            const MentionPageEvent.didUpdateViewStatus(
              (null, false, true),
            ),
          );
        },
      );
  }

  Future<String?> _fetchBlockContent() async {
    if (blockId == null) {
      return null;
    }

    final documentResult =
        await _documentService.getDocument(documentId: pageId);
    final document = documentResult.fold((l) => l, (f) => null);
    if (document == null) {
      Log.error('unable to get the document for page $pageId');
      return null;
    }
    final blockResult = await _documentService.getBlockFromDocument(
      document: document,
      blockId: blockId!,
    );
    final block = blockResult.fold((l) => l, (f) => null);
    if (block == null) {
      Log.error('unable to get the block $blockId from the document $pageId');
      return null;
    }

    final node = document.buildNode(blockId!);
    _blockTextId = (node?.externalValues as ExternalValues?)?.externalId;
    _initialDelta = node?.delta;
    _block = block;

    return _initialDelta?.toPlainText();
  }

  Future<void> _startListeningDocument() async {
    // only observe the block content if the block id is not null
    if (blockId == null ||
        _blockTextId == null ||
        _initialDelta == null ||
        _block == null) {
      return;
    }

    _documentListener = DocumentListener(id: pageId)
      ..start(
        onDocEventUpdate: (docEvent) {
          debugPrint('docEvent: ${docEvent.toProto3Json()}');
          for (final block in docEvent.events) {
            for (final event in block.event) {
              if (event.id == _blockTextId) {
                _updateBlockContent(event.value);
              }
            }
          }
        },
      );
  }

  Future<MentionPageStatus> _fetchView(String pageId) async {
    // Try to fetch the view from the main storage
    final view = await ViewBackendService.getView(pageId).then(
      (value) => value.toNullable(),
    );

    if (view != null) {
      return (view, false, false);
    }

    // if the view is not found, try to fetch from trash
    final trashViews = await TrashService().readTrash();
    final trash = trashViews.fold(
      (l) => l.items.firstWhereOrNull((element) => element.id == pageId),
      (r) => null,
    );
    if (trash != null) {
      final trashView = ViewPB()
        ..id = trash.id
        ..name = trash.name;
      return (trashView, true, false);
    }

    Log.info('No view found for page $pageId');
    return (null, false, true);
  }

  void _updateBlockContent(String deltaJson) {
    if (_initialDelta == null || _block == null) {
      return;
    }

    try {
      final incremental = Delta.fromJson(jsonDecode(deltaJson));
      final delta = _initialDelta!.compose(incremental);
      final content = delta.toPlainText();
      add(MentionPageEvent.didUpdateBlockContent(content));
      _initialDelta = delta;
    } catch (e) {
      Log.error('failed to update block content: $e');
    }
  }
}

@freezed
class MentionPageEvent with _$MentionPageEvent {
  const factory MentionPageEvent.initial() = _Initial;
  const factory MentionPageEvent.didUpdateBlockContent(
    String content,
  ) = _DidUpdateBlockContent;
  const factory MentionPageEvent.didUpdateViewStatus(MentionPageStatus status) =
      _DidUpdateViewStatus;
}

@freezed
class MentionPageState with _$MentionPageState {
  const factory MentionPageState({
    required bool isLoading,
    required bool isInTrash,
    required bool isDeleted,
    // non-null case:
    // - page is found
    // - page is in trash
    // null case:
    // - page is deleted
    required ViewPB? view,
    // the plain text content of the block
    // it doesn't contain any formatting
    required String blockContent,
  }) = _MentionPageState;

  factory MentionPageState.initial() => const MentionPageState(
        isLoading: true,
        isInTrash: false,
        isDeleted: false,
        blockContent: '',
        view: null,
      );
}
