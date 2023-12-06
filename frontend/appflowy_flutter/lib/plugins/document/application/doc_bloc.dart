import 'dart:async';

import 'package:appflowy/plugins/document/application/doc_service.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/editor_transaction_adapter.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/doc/doc_listener.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show
        EditorState,
        LogLevel,
        TransactionTime,
        Selection,
        Position,
        paragraphNode;
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_bloc.freezed.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  DocumentBloc({
    required this.view,
  })  : _documentListener = DocumentListener(id: view.id),
        _viewListener = ViewListener(viewId: view.id),
        super(DocumentState.initial()) {
    on<DocumentEvent>(_onDocumentEvent);
  }

  final ViewPB view;

  final DocumentListener _documentListener;
  final ViewListener _viewListener;

  final DocumentService _documentService = DocumentService();
  final TrashService _trashService = TrashService();

  late final TransactionAdapter _transactionAdapter = TransactionAdapter(
    documentId: view.id,
    documentService: _documentService,
  );

  EditorState? editorState;
  StreamSubscription? _subscription;

  @override
  Future<void> close() async {
    await _viewListener.stop();
    await _subscription?.cancel();
    await _documentService.closeDocument(view: view);
    editorState?.cancelSubscription();
    return super.close();
  }

  Future<void> _onDocumentEvent(
    DocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    await event.map(
      initial: (Initial value) async {
        final state = await _fetchDocumentState();
        await _subscribe(state);
        emit(state);
      },
      moveToTrash: (MoveToTrash value) async {
        emit(state.copyWith(isDeleted: true));
      },
      restore: (Restore value) async {
        emit(state.copyWith(isDeleted: false));
      },
      deletePermanently: (DeletePermanently value) async {
        final result = await _trashService.deleteViews([view.id]);
        final forceClose = result.fold((l) => true, (r) => false);
        emit(state.copyWith(forceClose: forceClose));
      },
      restorePage: (RestorePage value) async {
        final result = await _trashService.putback(view.id);
        final isDeleted = result.fold((l) => false, (r) => true);
        emit(state.copyWith(isDeleted: isDeleted));
      },
    );
  }

  Future<void> _subscribe(DocumentState state) async {
    _onViewChanged();
    _onDocumentChanged();

    // create the editor state
    await state.loadingState.whenOrNull(
      finish: (data) async => data.map((r) {
        _initAppFlowyEditorState(r);
      }),
    );
  }

  /// subscribe to the view(document page) change
  void _onViewChanged() {
    _viewListener.start(
      onViewMoveToTrash: (r) {
        r.swap().map((r) => add(const DocumentEvent.moveToTrash()));
      },
      onViewDeleted: (r) {
        r.swap().map((r) => add(const DocumentEvent.moveToTrash()));
      },
      onViewRestored: (r) =>
          r.swap().map((r) => add(const DocumentEvent.restore())),
    );
  }

  /// subscribe to the document content change
  void _onDocumentChanged() {
    _documentListener.start(
      didReceiveUpdate: syncDocumentDataPB,
    );
  }

  /// Fetch document
  Future<DocumentState> _fetchDocumentState() async {
    final result = await _documentService.openDocument(viewId: view.id);
    return state.copyWith(
      loadingState: DocumentLoadingState.finish(result),
    );
  }

  Future<void> _initAppFlowyEditorState(DocumentDataPB data) async {
    final document = data.toDocument();
    if (document == null) {
      assert(false, 'document is null');
      return;
    }

    final editorState = EditorState(document: document);
    this.editorState = editorState;

    // subscribe to the document change from the editor
    _subscription = editorState.transactionStream.listen((event) async {
      final time = event.$1;
      if (time != TransactionTime.before) {
        return;
      }
      await _transactionAdapter.apply(event.$2, editorState);

      // check if the document is empty.
      applyRules();

      if (!isClosed) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(state.copyWith(isDocumentEmpty: editorState.document.isEmpty));
      }
    });

    // output the log from the editor when debug mode
    if (kDebugMode) {
      editorState.logConfiguration
        ..level = LogLevel.all
        ..handler = (log) {
          // Log.debug(log);
        };
    }
  }

  Future<void> applyRules() async {
    ensureAtLeastOneParagraphExists();
    ensureLastNodeIsEditable();
  }

  Future<void> ensureLastNodeIsEditable() async {
    final editorState = this.editorState;
    if (editorState == null) {
      return;
    }
    final document = editorState.document;
    final lastNode = document.root.children.lastOrNull;
    if (lastNode == null || lastNode.delta == null) {
      final transaction = editorState.transaction;
      transaction.insertNode([document.root.children.length], paragraphNode());
      transaction.afterSelection = transaction.beforeSelection;
      await editorState.apply(transaction);
    }
  }

  Future<void> ensureAtLeastOneParagraphExists() async {
    final editorState = this.editorState;
    if (editorState == null) {
      return;
    }
    final document = editorState.document;
    if (document.root.children.isEmpty) {
      final transaction = editorState.transaction;
      transaction.insertNode([0], paragraphNode());
      transaction.afterSelection = Selection.collapsed(
        Position(path: [0], offset: 0),
      );
      await editorState.apply(transaction);
    }
  }

  void syncDocumentDataPB(DocEventPB docEvent) {
    // prettyPrintJson(docEvent.toProto3Json());
    // todo: integrate the document change to the editor
    // for (final event in docEvent.events) {
    //   for (final blockEvent in event.event) {
    //     switch (blockEvent.command) {
    //       case DeltaTypePB.Inserted:
    //         break;
    //       case DeltaTypePB.Updated:
    //         break;
    //       case DeltaTypePB.Removed:
    //         break;
    //       default:
    //     }
    //   }
    // }
  }
}

@freezed
class DocumentEvent with _$DocumentEvent {
  const factory DocumentEvent.initial() = Initial;
  const factory DocumentEvent.moveToTrash() = MoveToTrash;
  const factory DocumentEvent.restore() = Restore;
  const factory DocumentEvent.restorePage() = RestorePage;
  const factory DocumentEvent.deletePermanently() = DeletePermanently;
}

@freezed
class DocumentState with _$DocumentState {
  const factory DocumentState({
    required DocumentLoadingState loadingState,
    required bool isDeleted,
    required bool forceClose,
    bool? isDocumentEmpty,
    UserProfilePB? userProfilePB,
  }) = _DocumentState;

  factory DocumentState.initial() => const DocumentState(
        loadingState: _Loading(),
        isDeleted: false,
        forceClose: false,
        isDocumentEmpty: null,
        userProfilePB: null,
      );
}

@freezed
class DocumentLoadingState with _$DocumentLoadingState {
  const factory DocumentLoadingState.loading() = _Loading;
  const factory DocumentLoadingState.finish(
    Either<FlowyError, DocumentDataPB> successOrFail,
  ) = _Finish;
}
