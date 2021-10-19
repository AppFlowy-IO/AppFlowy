import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

part 'doc_bloc.freezed.dart';

class DocBloc extends Bloc<DocEvent, DocState> {
  final IDoc docManager;

  DocBloc({required this.docManager}) : super(DocState.initial());

  @override
  Stream<DocState> mapEventToState(DocEvent event) async* {
    yield* event.map(
      initial: _initial,
    );
  }

  @override
  Future<void> close() async {
    docManager.closeDoc();

    await state.doc.fold(() => null, (doc) async {
      await doc.close();
    });
    return super.close();
  }

  Stream<DocState> _initial(Initial value) async* {
    final result = await docManager.readDoc();
    yield result.fold(
      (doc) {
        final flowyDoc = FlowyDoc(doc: doc, iDocImpl: docManager);
        return state.copyWith(
          doc: some(flowyDoc),
          loadState: DocLoadState.finish(left(flowyDoc)),
        );
      },
      (err) {
        return state.copyWith(
          doc: none(),
          loadState: DocLoadState.finish(right(err)),
        );
      },
    );
  }

  // Document _decodeListToDocument(Uint8List data) {
  //   final json = jsonDecode(utf8.decode(data));
  //   final document = Document.fromJson(json);
  //   return document;
  // }

  // Document _decodeJsonToDocument(String data) {
  //   final json = jsonDecode(data);
  //   final document = Document.fromJson(json);
  //   return document;
  // }
}

@freezed
class DocEvent with _$DocEvent {
  const factory DocEvent.initial() = Initial;
}

@freezed
class DocState with _$DocState {
  const factory DocState({required Option<FlowyDoc> doc, required DocLoadState loadState}) = _DocState;

  factory DocState.initial() => DocState(doc: none(), loadState: const _Loading());
}

@freezed
class DocLoadState with _$DocLoadState {
  const factory DocLoadState.loading() = _Loading;
  const factory DocLoadState.finish(Either<FlowyDoc, WorkspaceError> successOrFail) = _Finish;
}
