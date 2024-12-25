import 'dart:async';
import 'dart:convert';

import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/document_listener.dart';
import 'package:appflowy/plugins/document/application/document_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/delta/text_delta_extension.dart';
import 'package:appflowy/plugins/trash/application/prelude.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mention_page_bloc.freezed.dart';

typedef MentionPageStatus = (ViewPB? view, bool isInTrash, bool isDeleted);

class MentionPageBloc extends Bloc<MentionPageEvent, MentionPageState> {
  MentionPageBloc({
    required this.pageId,
    this.blockId,
    bool isSubPage = false,
  })  : _isSubPage = isSubPage,
        super(MentionPageState.initial()) {
    on<MentionPageEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final (view, isInTrash, isDeleted) =
                await ViewBackendService.getMentionPageStatus(pageId);

            String? blockContent;
            if (!_isSubPage) {
              blockContent = await _getBlockContent();
            }

            emit(
              state.copyWith(
                view: view,
                isLoading: false,
                isInTrash: isInTrash,
                isDeleted: isDeleted,
                blockContent: blockContent ?? '',
              ),
            );

            if (view != null) {
              _startListeningView();
              _startListeningTrash();

              if (!_isSubPage) {
                _startListeningDocument();
              }
            }
          },
          didUpdateViewStatus: (view, isDeleted) async {
            emit(
              state.copyWith(
                view: view,
                isDeleted: isDeleted ?? state.isDeleted,
              ),
            );
          },
          didUpdateTrashStatus: (isInTrash) async =>
              emit(state.copyWith(isInTrash: isInTrash)),
          didUpdateBlockContent: (content) {
            emit(
              state.copyWith(
                blockContent: content,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() {
    _viewListener?.stop();
    _trashListener?.close();
    _documentListener?.stop();
    return super.close();
  }

  final _documentService = DocumentService();

  final String pageId;
  final String? blockId;
  final bool _isSubPage;

  ViewListener? _viewListener;
  TrashListener? _trashListener;

  DocumentListener? _documentListener;
  BlockPB? _block;
  String? _blockTextId;
  Delta? _initialDelta;

  void _startListeningView() {
    _viewListener = ViewListener(viewId: pageId)
      ..start(
        onViewUpdated: (view) => add(
          MentionPageEvent.didUpdateViewStatus(view: view, isDeleted: false),
        ),
        onViewDeleted: (_) =>
            add(const MentionPageEvent.didUpdateViewStatus(isDeleted: true)),
      );
  }

  void _startListeningTrash() {
    _trashListener = TrashListener()
      ..start(
        trashUpdated: (trashOrFailed) {
          final trash = trashOrFailed.toNullable();
          if (trash != null) {
            final isInTrash = trash.any((t) => t.id == pageId);
            add(MentionPageEvent.didUpdateTrashStatus(isInTrash: isInTrash));
          }
        },
      );
  }

  Future<String> _convertDeltaToText(Delta? delta) async {
    if (delta == null) {
      return _initialDelta?.toPlainText() ?? '';
    }

    return delta.toText(
      getMentionPageName: (mentionedPageId) async {
        if (mentionedPageId == pageId) {
          // if the mention page is the current page, return the view name
          return state.view?.name ?? '';
        } else {
          // if the mention page is not the current page, return the mention page name
          final viewResult = await ViewBackendService.getView(mentionedPageId);
          final name = viewResult.fold((l) => l.name, (f) => '');
          return name;
        }
      },
    );
  }

  Future<String?> _getBlockContent() async {
    if (blockId == null) {
      return null;
    }

    final documentNodeResult = await _documentService.getDocumentNode(
      documentId: pageId,
      blockId: blockId!,
    );
    final documentNode = documentNodeResult.fold((l) => l, (f) => null);
    if (documentNode == null) {
      Log.error(
        'unable to get the document node for block $blockId in page $pageId',
      );
      return null;
    }

    final block = documentNode.$2;
    final node = documentNode.$3;

    _blockTextId = (node.externalValues as ExternalValues?)?.externalId;
    _initialDelta = node.delta;
    _block = block;

    return _convertDeltaToText(_initialDelta);
  }

  void _startListeningDocument() {
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
          for (final block in docEvent.events) {
            for (final event in block.event) {
              if (event.id == _blockTextId) {
                if (event.command == DeltaTypePB.Updated) {
                  _updateBlockContent(event.value);
                } else if (event.command == DeltaTypePB.Removed) {
                  add(const MentionPageEvent.didUpdateBlockContent(''));
                }
              }
            }
          }
        },
      );
  }

  Future<void> _updateBlockContent(String deltaJson) async {
    if (_initialDelta == null || _block == null) {
      return;
    }

    try {
      final incremental = Delta.fromJson(jsonDecode(deltaJson));
      final delta = _initialDelta!.compose(incremental);
      final content = await _convertDeltaToText(delta);
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
  const factory MentionPageEvent.didUpdateViewStatus({
    @Default(null) ViewPB? view,
    @Default(null) bool? isDeleted,
  }) = _DidUpdateViewStatus;
  const factory MentionPageEvent.didUpdateTrashStatus({
    required bool isInTrash,
  }) = _DidUpdateTrashStatus;
  const factory MentionPageEvent.didUpdateBlockContent(
    String content,
  ) = _DidUpdateBlockContent;
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
  }) = _MentionSubPageState;

  factory MentionPageState.initial() => const MentionPageState(
        isLoading: true,
        isInTrash: false,
        isDeleted: false,
        view: null,
        blockContent: '',
      );
}
