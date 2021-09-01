import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'doc_bloc.freezed.dart';

class DocBloc extends Bloc<DocEvent, DocState> {
  final IDoc iDocImpl;

  DocBloc(this.iDocImpl) : super(DocState.initial());

  @override
  Stream<DocState> mapEventToState(DocEvent event) async* {
    yield* event.map(
      initial: (e) async* {},
      close: (Close value) async* {},
    );
  }
}

@freezed
abstract class DocEvent with _$DocEvent {
  const factory DocEvent.initial() = Initial;
  const factory DocEvent.close() = Close;
}

@freezed
abstract class DocState implements _$DocState {
  const factory DocState({
    required bool isSaving,
  }) = _DocState;

  factory DocState.initial() => const DocState(
        isSaving: false,
      );
}
