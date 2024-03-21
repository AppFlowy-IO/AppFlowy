import 'dart:async';

import 'package:appflowy/plugins/document/application/collab_document_adapter.dart';
import 'package:appflowy/plugins/document/application/doc_service.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/editor_transaction_adapter.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/doc/doc_listener.dart';
import 'package:appflowy/workspace/application/doc/sync_state_listener.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show
        EditorState,
        LogLevel,
        TransactionTime,
        Selection,
        Position,
        paragraphNode;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'doc_bloc.freezed.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  DocumentBloc({
    required this.view,
  })  : _documentListener = DocumentListener(id: view.id),
        _syncStateListener = DocumentSyncStateListener(id: view.id),
        _viewListener = ViewListener(viewId: view.id),
        super(DocumentState.initial()) {
    on<DocumentEvent>(_onDocumentEvent);
  }

  final ViewPB view;

  final DocumentListener _documentListener;
  final DocumentSyncStateListener _syncStateListener;
  final ViewListener _viewListener;

  final DocumentService _documentService = DocumentService();
  final TrashService _trashService = TrashService();

  late CollabDocumentAdapter _collabDocumentAdapter;

  late final TransactionAdapter _transactionAdapter = TransactionAdapter(
    documentId: view.id,
    documentService: _documentService,
  );

  StreamSubscription? _subscription;

  bool get isLocalMode {
    final userProfilePB = state.userProfilePB;
    final type = userProfilePB?.authenticator ?? AuthenticatorPB.Local;
    return type == AuthenticatorPB.Local;
  }

  @override
  Future<void> close() async {
    await _documentListener.stop();
    await _syncStateListener.stop();
    await _viewListener.stop();
    await _subscription?.cancel();
    await _documentService.closeDocument(view: view);
    state.editorState?.service.keyboardService?.closeKeyboard();
    state.editorState?.dispose();
    return super.close();
  }

  Future<void> _onDocumentEvent(
    DocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    await event.when(
      initial: () async {
        final result = await _fetchDocumentState();
        _onViewChanged();
        _onDocumentChanged();
        final newState = await result.fold(
          (s) async {
            final userProfilePB =
                await getIt<AuthService>().getUser().toNullable();
            return state.copyWith(
              error: null,
              editorState: s,
              isLoading: false,
              userProfilePB: userProfilePB,
            );
          },
          (f) async => state.copyWith(
            error: f,
            editorState: null,
            isLoading: false,
          ),
        );
        emit(newState);
      },
      moveToTrash: () async {
        emit(state.copyWith(isDeleted: true));
      },
      restore: () async {
        emit(state.copyWith(isDeleted: false));
      },
      deletePermanently: () async {
        final result = await _trashService.deleteViews([view.id]);
        final forceClose = result.fold((l) => true, (r) => false);
        emit(state.copyWith(forceClose: forceClose));
      },
      restorePage: () async {
        final result = await _trashService.putback(view.id);
        final isDeleted = result.fold((l) => false, (r) => true);
        emit(state.copyWith(isDeleted: isDeleted));
      },
      syncStateChanged: (syncState) {
        emit(state.copyWith(syncState: syncState.value));
      },
    );
  }

  /// subscribe to the view(document page) change
  void _onViewChanged() {
    _viewListener.start(
      onViewMoveToTrash: (r) {
        r.map((r) => add(const DocumentEvent.moveToTrash()));
      },
      onViewDeleted: (r) {
        r.map((r) => add(const DocumentEvent.moveToTrash()));
      },
      onViewRestored: (r) => r.map((r) => add(const DocumentEvent.restore())),
    );
  }

  /// subscribe to the document content change
  void _onDocumentChanged() {
    _documentListener.start(
      didReceiveUpdate: syncDocumentDataPB,
    );

    _syncStateListener.start(
      didReceiveSyncState: (syncState) {
        if (!isClosed) {
          add(DocumentEvent.syncStateChanged(syncState));
        }
      },
    );
  }

  /// Fetch document
  Future<FlowyResult<EditorState?, FlowyError>> _fetchDocumentState() async {
    final result = await _documentService.openDocument(viewId: view.id);
    return result.fold(
      (s) async => FlowyResult.success(await _initAppFlowyEditorState(s)),
      (e) => FlowyResult.failure(e),
    );
  }

  Future<EditorState?> _initAppFlowyEditorState(DocumentDataPB data) async {
    final document = data.toDocument();
    if (document == null) {
      assert(false, 'document is null');
      return null;
    }

    final editorState = EditorState(document: document);

    _collabDocumentAdapter = CollabDocumentAdapter(editorState, view.id);

    // subscribe to the document change from the editor
    _subscription = editorState.transactionStream.listen((event) async {
      final time = event.$1;
      if (time != TransactionTime.before) {
        return;
      }
      await _transactionAdapter.apply(event.$2, editorState);

      // check if the document is empty.
      await applyRules();

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

    return editorState;
  }

  Future<void> applyRules() async {
    await Future.wait([
      ensureAtLeastOneParagraphExists(),
      ensureLastNodeIsEditable(),
    ]);
  }

  Future<void> ensureLastNodeIsEditable() async {
    final editorState = state.editorState;
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
    final editorState = state.editorState;
    if (editorState == null) {
      return;
    }
    final document = editorState.document;
    if (document.root.children.isEmpty) {
      final transaction = editorState.transaction;
      transaction.insertNode([0], paragraphNode());
      transaction.afterSelection = Selection.collapsed(
        Position(path: [0]),
      );
      await editorState.apply(transaction);
    }
  }

  Future<void> syncDocumentDataPB(DocEventPB docEvent) async {
    if (!docEvent.isRemote || !FeatureFlag.syncDocument.isOn) {
      return;
    }

    await _collabDocumentAdapter.syncV3();
  }
}

@freezed
class DocumentEvent with _$DocumentEvent {
  const factory DocumentEvent.initial() = Initial;
  const factory DocumentEvent.moveToTrash() = MoveToTrash;
  const factory DocumentEvent.restore() = Restore;
  const factory DocumentEvent.restorePage() = RestorePage;
  const factory DocumentEvent.deletePermanently() = DeletePermanently;
  const factory DocumentEvent.syncStateChanged(
    final DocumentSyncStatePB syncState,
  ) = syncStateChanged;
}

@freezed
class DocumentState with _$DocumentState {
  const factory DocumentState({
    required final bool isDeleted,
    required final bool forceClose,
    required final bool isLoading,
    required final DocumentSyncState syncState,
    bool? isDocumentEmpty,
    UserProfilePB? userProfilePB,
    EditorState? editorState,
    FlowyError? error,
  }) = _DocumentState;

  factory DocumentState.initial() => const DocumentState(
        isDeleted: false,
        forceClose: false,
        isLoading: true,
        syncState: DocumentSyncState.Syncing,
      );
}
