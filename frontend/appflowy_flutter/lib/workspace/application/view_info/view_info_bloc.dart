import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_info_bloc.freezed.dart';

class ViewInfoBloc extends Bloc<ViewInfoEvent, ViewInfoState> {
  ViewInfoBloc({required this.view}) : super(ViewInfoState.initial()) {
    on<ViewInfoEvent>((event, emit) {
      event.when(
        started: () {
          emit(state.copyWith(createdAt: view.createTime.toDateTime()));
        },
        unregisterEditorState: () {
          _clearWordCountService();
          emit(state.copyWith(documentCounters: null));
        },
        registerEditorState: (editorState) {
          _clearWordCountService();
          _wordCountService = WordCountService(editorState: editorState)
            ..addListener(_onWordCountChanged)
            ..register();

          emit(
            state.copyWith(
              documentCounters: _wordCountService!.documentCounters,
            ),
          );
        },
        wordCountChanged: () {
          emit(
            state.copyWith(
              documentCounters: _wordCountService?.documentCounters,
            ),
          );
        },
      );
    });
  }

  final ViewPB view;

  WordCountService? _wordCountService;

  @override
  Future<void> close() async {
    _clearWordCountService();
    await super.close();
  }

  void _onWordCountChanged() => add(const ViewInfoEvent.wordCountChanged());

  void _clearWordCountService() {
    _wordCountService
      ?..removeListener(_onWordCountChanged)
      ..dispose();
    _wordCountService = null;
  }
}

@freezed
class ViewInfoEvent with _$ViewInfoEvent {
  const factory ViewInfoEvent.started() = _Started;

  const factory ViewInfoEvent.unregisterEditorState() = _UnregisterEditorState;

  const factory ViewInfoEvent.registerEditorState({
    required EditorState editorState,
  }) = _RegisterEditorState;

  const factory ViewInfoEvent.wordCountChanged() = _WordCountChanged;
}

@freezed
class ViewInfoState with _$ViewInfoState {
  const factory ViewInfoState({
    required Counters? documentCounters,
    required DateTime? createdAt,
  }) = _ViewInfoState;

  factory ViewInfoState.initial() => const ViewInfoState(
        documentCounters: null,
        createdAt: null,
      );
}
