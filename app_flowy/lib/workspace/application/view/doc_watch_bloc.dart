import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flowy_sdk/protobuf/flowy-editor/errors.pb.dart';
part 'doc_watch_bloc.freezed.dart';

class DocWatchBloc extends Bloc<DocWatchEvent, DocWatchState> {
  final IDoc iDocImpl;

  DocWatchBloc({
    required this.iDocImpl,
  }) : super(const DocWatchState.loading());

  @override
  Stream<DocWatchState> mapEventToState(DocWatchEvent event) async* {
    yield* event.map(
      started: (_) async* {
        yield* _readDoc();
      },
    );
  }

  Stream<DocWatchState> _readDoc() async* {
    final docOrFail = await iDocImpl.readDoc();
    yield docOrFail.fold(
      (doc) => DocWatchState.loadDoc(doc),
      (error) => DocWatchState.loadFail(error),
    );
  }
}

@freezed
class DocWatchEvent with _$DocWatchEvent {
  const factory DocWatchEvent.started() = Started;
}

@freezed
class DocWatchState with _$DocWatchState {
  const factory DocWatchState.loading() = Loading;
  const factory DocWatchState.loadDoc(Doc doc) = LoadDoc;
  const factory DocWatchState.loadFail(EditorError error) = LoadFail;
}
