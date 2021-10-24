import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';
part 'doc_bloc.freezed.dart';

class DocBloc extends Bloc<DocEvent, DocState> {
  final IDoc docManager;
  late Document document;
  late StreamSubscription _subscription;

  DocBloc({required this.docManager}) : super(DocState.initial());

  @override
  Stream<DocState> mapEventToState(DocEvent event) async* {
    yield* event.map(initial: _initial);
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    docManager.closeDoc();
    return super.close();
  }

  Stream<DocState> _initial(Initial value) async* {
    final result = await docManager.readDoc();
    yield result.fold(
      (doc) {
        document = _decodeJsonToDocument(doc.data);
        _subscription = document.changes.listen((event) {
          final delta = event.item2;
          final documentDelta = document.toDelta();
          _composeDelta(delta, documentDelta);
        });
        return state.copyWith(loadState: DocLoadState.finish(left(unit)));
      },
      (err) {
        return state.copyWith(loadState: DocLoadState.finish(right(err)));
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
    Log.debug("Send json: $json");
    final result = await docManager.composeDelta(json: json);

    result.fold((rustDoc) {
      // final json = utf8.decode(doc.data);
      final rustDelta = Delta.fromJson(jsonDecode(rustDoc.data));
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
}

@freezed
class DocState with _$DocState {
  const factory DocState({
    required DocLoadState loadState,
  }) = _DocState;

  factory DocState.initial() => const DocState(loadState: _Loading());
}

@freezed
class DocLoadState with _$DocLoadState {
  const factory DocLoadState.loading() = _Loading;
  const factory DocLoadState.finish(Either<Unit, WorkspaceError> successOrFail) = _Finish;
}
