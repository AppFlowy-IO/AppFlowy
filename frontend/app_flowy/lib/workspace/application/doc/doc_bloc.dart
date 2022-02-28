import 'dart:convert';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-collaboration/document_info.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/trash.pb.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document, Delta;
import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
part 'doc_bloc.freezed.dart';

typedef FlutterQuillDocument = Document;

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final View view;
  final ViewListener listener;
  late FlutterQuillDocument document;
  StreamSubscription? _subscription;
  final String docId;

  DocumentBloc({
    required this.view,
    required this.listener,
    required this.docId,
  }) : super(DocumentState.initial()) {
    on<DocumentEvent>((event, emit) async {
      await event.map(
        initial: (Initial value) async {
          await _initial(value, emit);
        },
        deleted: (Deleted value) async {
          emit(state.copyWith(isDeleted: true));
        },
        restore: (Restore value) async {
          emit(state.copyWith(isDeleted: false));
        },
        deletePermanently: (DeletePermanently value) async {
          final result = await _deleteViews([Tuple2(view.id, TrashType.TrashView)]);
          final newState = result.fold((l) => state.copyWith(forceClose: true), (r) => state);
          emit(newState);
        },
        restorePage: (RestorePage value) async {
          final id = TrashId.create()..id = view.id;
          final result = await FolderEventPutbackTrash(id).send();

          final newState = result.fold((l) => state.copyWith(isDeleted: false), (r) => state);
          emit(newState);
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.close();

    if (_subscription != null) {
      await _subscription?.cancel();
    }

    final request = ViewId(value: docId);
    FolderEventCloseView(request).send();

    return super.close();
  }

  Future<void> _initial(Initial value, Emitter<DocumentState> emit) async {
    listener.deletedNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocumentEvent.deleted()),
        (error) {},
      );
    });

    listener.restoredNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocumentEvent.restore()),
        (error) {},
      );
    });

    listener.start();

    final request = ViewId(value: docId);
    final result = await FolderEventOpenView(request).send();

    result.fold(
      (doc) {
        document = _decodeJsonToDocument(doc.deltaJson);
        _subscription = document.changes.listen((event) {
          final delta = event.item2;
          final documentDelta = document.toDelta();
          _composeDelta(delta, documentDelta);
        });
        emit(state.copyWith(loadingState: DocumentLoadingState.finish(left(unit))));
      },
      (err) {
        emit(state.copyWith(loadingState: DocumentLoadingState.finish(right(err))));
      },
    );
  }

  // Document _decodeListToDocument(Uint8List data) {
  //   final json = jsonDecode(utf8.decode(data));
  //   final document = Document.fromJson(json);
  //   return document;
  // }

  void _composeDelta(Delta composedDelta, Delta documentDelta) async {
    final json = jsonEncode(composedDelta.toJson());
    Log.debug("doc_id: $view.id - Send json: $json");

    final request = DocumentDelta.create()
      ..docId = docId
      ..deltaJson = json;
    final result = await FolderEventApplyDocDelta(request).send();

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.deltaJson));
      if (documentDelta != rustDelta) {
        Log.error("Receive : $rustDelta");
        Log.error("Expected : $documentDelta");
      }
    }, (r) => null);
  }

  Future<Either<Unit, FlowyError>> _deleteViews(List<Tuple2<String, TrashType>> trashList) {
    final items = trashList.map((trash) {
      return TrashId.create()
        ..id = trash.value1
        ..ty = trash.value2;
    });

    final ids = RepeatedTrashId(items: items);
    return FolderEventDeleteTrash(ids).send();
  }

  Document _decodeJsonToDocument(String data) {
    final json = jsonDecode(data);
    final document = Document.fromJson(json);
    return document;
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
  const factory DocumentLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}
