import 'dart:convert';
import 'package:appflowy/plugins/document/presentation/plugins/cover/cover_node_widget.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/doc/doc_listener.dart';
import 'package:appflowy/plugins/document/application/doc_service.dart';
import 'package:appflowy_backend/protobuf/flowy-document/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pbserver.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show EditorState, Document, Transaction, Node;
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
import 'package:appflowy/util/either_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/entities.pb.dart';
part 'doc_bloc.freezed.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final ViewPB view;
  final DocumentService _documentService;
  final DocumentListener _docListener;

  final ViewListener _listener;
  final TrashService _trashService;
  EditorState? editorState;
  StreamSubscription? _subscription;

  DocumentBloc({
    required this.view,
  })  : _documentService = DocumentService(),
        _docListener = DocumentListener(id: view.id),
        _listener = ViewListener(view: view),
        _trashService = TrashService(),
        super(DocumentState.initial()) {
    on<DocumentEvent>((event, emit) async {
      await event.map(
        initial: (Initial value) async {
          _listenOnDocChange();
          await _initial(value, emit);
          _listenOnViewChange();
        },
        deleted: (Deleted value) async {
          emit(state.copyWith(isDeleted: true));
        },
        restore: (Restore value) async {
          emit(state.copyWith(isDeleted: false));
        },
        deletePermanently: (DeletePermanently value) async {
          final result = await _trashService.deleteViews([view.id]);

          final newState = result.fold(
              (l) => state.copyWith(forceClose: true), (r) => state);
          emit(newState);
        },
        restorePage: (RestorePage value) async {
          final result = await _trashService.putback(view.id);
          final newState = result.fold(
              (l) => state.copyWith(isDeleted: false), (r) => state);
          emit(newState);
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _listener.stop();

    if (_subscription != null) {
      await _subscription?.cancel();
    }

    await _documentService.closeDocument(docId: view.id);
    await _documentService.closeDocumentV2(view: view);
    return super.close();
  }

  Future<void> _initial(Initial value, Emitter<DocumentState> emit) async {
    final userProfile = await UserBackendService.getCurrentUserProfile();
    if (userProfile.isRight()) {
      return emit(
        state.copyWith(
          loadingState: DocumentLoadingState.finish(
            right(userProfile.asRight()),
          ),
        ),
      );
    }
    final result = await _documentService.openDocument(view: view);
    // test code
    final document = await _documentService.openDocumentV2(view: view);
    BlockPB? root;
    document.fold((l) {
      print('---------<open document v2>-----------');
      print('page id = ${l.pageId}');
      l.blocks.blocks.forEach((key, value) {
        print('-----<block begin>-----');
        print('block = $value');
        if (value.ty == 'page') {
          root = value;
        }
        print('-----<block end>-----');
      });
      print('---------<open document v2>-----------');
    }, (r) {});
    if (root != null) {
      await _documentService.applyAction(
        view: view,
        actions: [
          BlockActionPB(
            action: BlockActionTypePB.Insert,
            payload: BlockActionPayloadPB(
              block: BlockPB()
                ..id = 'id_0'
                ..ty = 'text'
                ..parentId = root!.id,
            ),
          ),
        ],
      );
    }

    return result.fold(
      (documentData) async {
        await _initEditorState(documentData).whenComplete(() {
          emit(
            state.copyWith(
              loadingState: DocumentLoadingState.finish(left(unit)),
              userProfilePB: userProfile.asLeft(),
            ),
          );
        });
      },
      (err) async {
        emit(
          state.copyWith(
            loadingState: DocumentLoadingState.finish(right(err)),
          ),
        );
      },
    );
  }

  void _listenOnViewChange() {
    _listener.start(
      onViewDeleted: (result) {
        result.fold(
          (view) => add(const DocumentEvent.deleted()),
          (error) {},
        );
      },
      onViewRestored: (result) {
        result.fold(
          (view) => add(const DocumentEvent.restore()),
          (error) {},
        );
      },
    );
  }

  void _listenOnDocChange() {
    _docListener.start(
      didReceiveUpdate: () {
        print('---------<receive document update>-----------');
      },
    );
  }

  Future<void> _initEditorState(DocumentDataPB documentData) async {
    final document = Document.fromJson(jsonDecode(documentData.content));
    final editorState = EditorState(document: document);
    this.editorState = editorState;

    // listen on document change
    _subscription = editorState.transactionStream.listen((transaction) {
      final json = jsonEncode(TransactionAdaptor(transaction).toJson());
      _documentService
          .applyEdit(docId: view.id, operations: json)
          .then((result) {
        result.fold(
          (l) => null,
          (err) => Log.error(err),
        );
      });
    });
    // log
    if (kDebugMode) {
      editorState.logConfiguration.handler = (log) {
        Log.debug(log);
      };
    }
    // migration
    final migration = DocumentMigration(editorState: editorState);
    await migration.apply();
  }
}

@freezed
class DocumentEvent with _$DocumentEvent {
  const factory DocumentEvent.initial() = Initial;
  const factory DocumentEvent.deleted() = Deleted;
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
    UserProfilePB? userProfilePB,
  }) = _DocumentState;

  factory DocumentState.initial() => const DocumentState(
        loadingState: _Loading(),
        isDeleted: false,
        forceClose: false,
        userProfilePB: null,
      );
}

@freezed
class DocumentLoadingState with _$DocumentLoadingState {
  const factory DocumentLoadingState.loading() = _Loading;
  const factory DocumentLoadingState.finish(
      Either<Unit, FlowyError> successOrFail) = _Finish;
}

/// Uses to erase the different between appflowy editor and the backend
class TransactionAdaptor {
  final Transaction transaction;
  TransactionAdaptor(this.transaction);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (transaction.operations.isNotEmpty) {
      // The backend uses [0,0] as the beginning path, but the editor uses [0].
      // So it needs to extend the path by inserting `0` at the head for all
      // operations before passing to the backend.
      json['operations'] = transaction.operations
          .map((e) => e.copyWith(path: [0, ...e.path]).toJson())
          .toList();
    }
    if (transaction.afterSelection != null) {
      final selection = transaction.afterSelection!;
      final start = selection.start;
      final end = selection.end;
      json['after_selection'] = selection
          .copyWith(
            start: start.copyWith(path: [0, ...start.path]),
            end: end.copyWith(path: [0, ...end.path]),
          )
          .toJson();
    }
    if (transaction.beforeSelection != null) {
      final selection = transaction.beforeSelection!;
      final start = selection.start;
      final end = selection.end;
      json['before_selection'] = selection
          .copyWith(
            start: start.copyWith(path: [0, ...start.path]),
            end: end.copyWith(path: [0, ...end.path]),
          )
          .toJson();
    }
    return json;
  }
}

class DocumentMigration {
  const DocumentMigration({
    required this.editorState,
  });

  final EditorState editorState;

  /// Migrate the document to the latest version.
  Future<void> apply() async {
    final transaction = editorState.transaction;

    // A temporary solution to migrate the document to the latest version.
    // Once the editor is stable, we can remove this.

    // cover plugin
    if (editorState.document.nodeAtPath([0])?.type != kCoverType) {
      transaction.insertNode(
        [0],
        Node(type: kCoverType),
      );
    }

    transaction.afterSelection = null;

    if (transaction.operations.isNotEmpty) {
      editorState.apply(transaction);
    }
  }
}
