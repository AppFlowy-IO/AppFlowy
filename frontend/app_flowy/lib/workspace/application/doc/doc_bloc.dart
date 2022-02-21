import 'dart:convert';
import 'package:app_flowy/workspace/infrastructure/repos/doc_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/trash_repo.dart';
import 'package:app_flowy/workspace/infrastructure/repos/view_repo.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/trash.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
part 'doc_bloc.freezed.dart';

class DocBloc extends Bloc<DocEvent, DocState> {
  final View view;
  final DocRepository repo;
  final ViewListener listener;
  final TrashRepo trashRepo;
  late Document document;
  StreamSubscription? _subscription;

  DocBloc({
    required this.view,
    required this.repo,
    required this.listener,
    required this.trashRepo,
  }) : super(DocState.initial()) {
    on<DocEvent>((event, emit) async {
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
          final result = await trashRepo.deleteViews([Tuple2(view.id, TrashType.TrashView)]);
          final newState = result.fold((l) => state.copyWith(forceClose: true), (r) => state);
          emit(newState);
        },
        restorePage: (RestorePage value) async {
          final result = await trashRepo.putback(view.id);
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

    repo.closeDoc();
    return super.close();
  }

  Future<void> _initial(Initial value, Emitter<DocState> emit) async {
    listener.deletedNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocEvent.deleted()),
        (error) {},
      );
    });

    listener.restoredNotifier.addPublishListener((result) {
      result.fold(
        (view) => add(const DocEvent.restore()),
        (error) {},
      );
    });

    listener.start();
    final result = await repo.readDoc();
    result.fold(
      (doc) {
        document = _decodeJsonToDocument(doc.deltaJson);
        _subscription = document.changes.listen((event) {
          final delta = event.item2;
          final documentDelta = document.toDelta();
          _composeDelta(delta, documentDelta);
        });
        emit(state.copyWith(loadState: DocLoadState.finish(left(unit))));
      },
      (err) {
        emit(state.copyWith(loadState: DocLoadState.finish(right(err))));
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
    final result = await repo.composeDelta(data: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.deltaJson));
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
class DocEvent with _$DocEvent {
  const factory DocEvent.initial() = Initial;
  const factory DocEvent.deleted() = Deleted;
  const factory DocEvent.restore() = Restore;
  const factory DocEvent.restorePage() = RestorePage;
  const factory DocEvent.deletePermanently() = DeletePermanently;
}

@freezed
class DocState with _$DocState {
  const factory DocState({
    required DocLoadState loadState,
    required bool isDeleted,
    required bool forceClose,
  }) = _DocState;

  factory DocState.initial() => const DocState(
        loadState: _Loading(),
        isDeleted: false,
        forceClose: false,
      );
}

@freezed
class DocLoadState with _$DocLoadState {
  const factory DocLoadState.loading() = _Loading;
  const factory DocLoadState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}
