import 'dart:convert';
import 'package:app_flowy/plugins/trash/application/trash_service.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/plugins/doc/application/doc_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show EditorState, Document, Transaction;
import 'package:flowy_sdk/protobuf/flowy-folder/trash.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

part 'doc_bloc.freezed.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final ViewPB view;
  final DocumentService service;

  final ViewListener listener;
  final TrashService trashService;
  late EditorState editorState;
  StreamSubscription? _subscription;

  DocumentBloc({
    required this.view,
    required this.service,
    required this.listener,
    required this.trashService,
  }) : super(DocumentState.initial()) {
    on<DocumentEvent>((event, emit) async {
      await event.map(
        initial: (Initial value) async {
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
          final result = await trashService
              .deleteViews([Tuple2(view.id, TrashType.TrashView)]);

          final newState = result.fold(
              (l) => state.copyWith(forceClose: true), (r) => state);
          emit(newState);
        },
        restorePage: (RestorePage value) async {
          final result = await trashService.putback(view.id);
          final newState = result.fold(
              (l) => state.copyWith(isDeleted: false), (r) => state);
          emit(newState);
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();

    if (_subscription != null) {
      await _subscription?.cancel();
    }

    await service.closeDocument(docId: view.id);
    return super.close();
  }

  Future<void> _initial(Initial value, Emitter<DocumentState> emit) async {
    final result = await service.openDocument(docId: view.id);
    result.fold(
      (block) {
        final document = Document.fromJson(jsonDecode(block.snapshot));
        editorState = EditorState(document: document);
        _listenOnDocumentChange();
        emit(
          state.copyWith(
            loadingState: DocumentLoadingState.finish(left(unit)),
          ),
        );
      },
      (err) {
        emit(
          state.copyWith(
            loadingState: DocumentLoadingState.finish(right(err)),
          ),
        );
      },
    );
  }

  void _listenOnViewChange() {
    listener.start(
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

  void _listenOnDocumentChange() {
    _subscription = editorState.transactionStream.listen((transaction) {
      final json = jsonEncode(TransactionAdaptor(transaction).toJson());
      service.applyEdit(docId: view.id, operations: json).then((result) {
        result.fold(
          (l) => null,
          (err) => Log.error(err),
        );
      });
    });
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
  }) = _DocumentState;

  factory DocumentState.initial() => const DocumentState(
        loadingState: _Loading(),
        isDeleted: false,
        forceClose: false,
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
