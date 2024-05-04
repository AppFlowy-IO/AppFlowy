import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_row_bloc.freezed.dart';

class SummaryRowBloc extends Bloc<SummaryRowEvent, SummaryRowState> {
  SummaryRowBloc({
    required this.viewId,
    required this.rowId,
    required this.fieldId,
  }) : super(SummaryRowState.initial()) {
    _dispatch();
  }

  final String viewId;
  final String rowId;
  final String fieldId;

  void _dispatch() {
    on<SummaryRowEvent>(
      (event, emit) async {
        event.when(
          startSummary: () {
            final params = SummaryRowPB(
              viewId: viewId,
              rowId: rowId,
              fieldId: fieldId,
            );
            emit(
              state.copyWith(
                loadingState: const LoadingState.loading(),
                error: null,
              ),
            );

            DatabaseEventSummarizeRow(params).send().then(
                  (result) => {
                    if (!isClosed) add(SummaryRowEvent.finishSummary(result)),
                  },
                );
          },
          finishSummary: (result) {
            result.fold(
              (s) => {
                emit(
                  state.copyWith(
                    loadingState: const LoadingState.finish(),
                    error: null,
                  ),
                ),
              },
              (err) => {
                emit(
                  state.copyWith(
                    loadingState: const LoadingState.finish(),
                    error: err,
                  ),
                ),
              },
            );
          },
        );
      },
    );
  }
}

@freezed
class SummaryRowEvent with _$SummaryRowEvent {
  const factory SummaryRowEvent.startSummary() = _DidStartSummary;
  const factory SummaryRowEvent.finishSummary(
      FlowyResult<void, FlowyError> result) = _DidFinishSummary;
}

@freezed
class SummaryRowState with _$SummaryRowState {
  const factory SummaryRowState({
    required LoadingState loadingState,
    required FlowyError? error,
  }) = _SummaryRowState;

  factory SummaryRowState.initial() {
    return const SummaryRowState(
      loadingState: LoadingState.finish(),
      error: null,
    );
  }
}

@freezed
class LoadingState with _$LoadingState {
  const factory LoadingState.loading() = _Loading;
  const factory LoadingState.finish() = _Finish;
}
