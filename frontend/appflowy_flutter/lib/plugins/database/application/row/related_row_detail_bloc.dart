import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../database_controller.dart';
import 'row_controller.dart';

part 'related_row_detail_bloc.freezed.dart';

class RelatedRowDetailPageBloc
    extends Bloc<RelatedRowDetailPageEvent, RelatedRowDetailPageState> {
  RelatedRowDetailPageBloc({
    required String databaseId,
    required String initialRowId,
  }) : super(const RelatedRowDetailPageState.loading()) {
    _dispatch();
    _init(databaseId, initialRowId);
  }

  @override
  Future<void> close() {
    state.whenOrNull(
      ready: (databaseController, rowController) async {
        await rowController.dispose();
        await databaseController.dispose();
      },
    );
    return super.close();
  }

  void _dispatch() {
    on<RelatedRowDetailPageEvent>((event, emit) async {
      event.when(
        didInitialize: (databaseController, rowController) {
          state.maybeWhen(
            ready: (_, oldRowController) async {
              await oldRowController.dispose();
              emit(
                RelatedRowDetailPageState.ready(
                  databaseController: databaseController,
                  rowController: rowController,
                ),
              );
            },
            orElse: () {
              emit(
                RelatedRowDetailPageState.ready(
                  databaseController: databaseController,
                  rowController: rowController,
                ),
              );
            },
          );
        },
      );
    });
  }

  /// initialize bloc through the `database_id` and `row_id`. The process is as
  /// follows:
  /// 1. use the `database_id` to get the database meta, which contains the
  /// `inline_view_id`
  /// 2. use the `inline_view_id` to instantiate a `DatabaseController`.
  /// 3. use the `row_id` with the DatabaseController` to create `RowController`
  void _init(String databaseId, String initialRowId) async {
    final databaseMeta =
        await DatabaseEventGetDatabaseMeta(DatabaseIdPB(value: databaseId))
            .send()
            .fold<DatabaseMetaPB?>((s) => s, (f) => null);
    if (databaseMeta == null) {
      return;
    }
    final inlineView =
        await ViewBackendService.getView(databaseMeta.inlineViewId)
            .fold((viewPB) => viewPB, (f) => null);
    if (inlineView == null) {
      return;
    }
    final databaseController = DatabaseController(view: inlineView);
    await databaseController.open().fold(
          (s) => databaseController.setIsLoading(false),
          (f) => null,
        );
    final rowInfo = databaseController.rowCache.getRow(initialRowId);
    if (rowInfo == null) {
      return;
    }
    final rowController = RowController(
      rowMeta: rowInfo.rowMeta,
      viewId: inlineView.id,
      rowCache: databaseController.rowCache,
    );
    add(
      RelatedRowDetailPageEvent.didInitialize(
        databaseController,
        rowController,
      ),
    );
  }
}

@freezed
class RelatedRowDetailPageEvent with _$RelatedRowDetailPageEvent {
  const factory RelatedRowDetailPageEvent.didInitialize(
    DatabaseController databaseController,
    RowController rowController,
  ) = _DidInitialize;
}

@freezed
class RelatedRowDetailPageState with _$RelatedRowDetailPageState {
  const factory RelatedRowDetailPageState.loading() = _LoadingState;
  const factory RelatedRowDetailPageState.ready({
    required DatabaseController databaseController,
    required RowController rowController,
  }) = _ReadyState;
}
