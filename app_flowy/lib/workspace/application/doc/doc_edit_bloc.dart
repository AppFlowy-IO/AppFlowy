import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'doc_edit_bloc.freezed.dart';

class DocEditBloc extends Bloc<DocEditEvent, DocEditState> {
  final IDoc iDocImpl;

  DocEditBloc(this.iDocImpl) : super(DocEditState.initial());

  @override
  Stream<DocEditState> mapEventToState(DocEditEvent event) async* {
    yield* event.map(
      initial: (e) async* {},
      close: (Close value) async* {
        iDocImpl.closeDoc();
      },
    );
  }
}

@freezed
class DocEditEvent with _$DocEditEvent {
  const factory DocEditEvent.initial() = Initial;
  const factory DocEditEvent.close() = Close;
}

@freezed
class DocEditState with _$DocEditState {
  const factory DocEditState({
    required bool isSaving,
  }) = _DocEditState;

  factory DocEditState.initial() => const DocEditState(
        isSaving: false,
      );
}
