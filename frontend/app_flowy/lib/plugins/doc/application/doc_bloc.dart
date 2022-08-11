import 'dart:convert';
import 'package:app_flowy/plugins/trash/application/trash_service.dart';
import 'package:app_flowy/workspace/application/view/view_listener.dart';
import 'package:app_flowy/plugins/doc/application/doc_service.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/trash.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document, Delta;
import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

part 'doc_bloc.freezed.dart';

typedef FlutterQuillDocument = Document;

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final ViewPB view;
  final DocumentService service;

  final ViewListener listener;
  final TrashService trashService;
  late FlutterQuillDocument document;
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
    final result = await service.openDocument(docId: view.id);
    result.fold(
      (block) {
        document = _decodeJsonToDocument(block.deltaStr);
        _subscription = document.changes.listen((event) {
          final delta = event.item2;
          final documentDelta = document.toDelta();
          _composeDelta(delta, documentDelta);
        });
        emit(state.copyWith(
            loadingState: DocumentLoadingState.finish(left(unit))));
      },
      (err) {
        emit(state.copyWith(
            loadingState: DocumentLoadingState.finish(right(err))));
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
    final result = await service.composeDelta(docId: view.id, data: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.deltaStr));
      if (documentDelta != rustDelta) {
        Log.error("Receive : $rustDelta");
        Log.error("Expected : $documentDelta");
      }
    }, (r) => null);
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
  const factory DocumentLoadingState.finish(
      Either<Unit, FlowyError> successOrFail) = _Finish;
}
