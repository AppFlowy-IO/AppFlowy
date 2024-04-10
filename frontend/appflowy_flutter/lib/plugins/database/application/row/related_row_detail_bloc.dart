import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
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
      ready: (databaseController, rowController) {
        rowController.dispose();
        databaseController.dispose();
      },
    );
    return super.close();
  }

  void _dispatch() {
    on<RelatedRowDetailPageEvent>((event, emit) async {
      event.when(
        didInitialize: (databaseController, rowController) {
          state.maybeWhen(
            ready: (_, oldRowController) {
              oldRowController.dispose();
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

  void _init(String databaseId, String initialRowId) async {
    final getDatabaseResult = await DatabaseEventGetDatabases().send();
    final databaseMeta = getDatabaseResult.fold<DatabaseMetaPB?>(
      (s) =>
          s.items.firstWhereOrNull((metaPB) => metaPB.databaseId == databaseId),
      (f) => null,
    );
    if (databaseMeta == null) {
      return;
    }
    final getInlineViewResult =
        await ViewBackendService.getView(databaseMeta.inlineViewId);
    final inlineView =
        getInlineViewResult.fold((viewPB) => viewPB, (f) => null);
    if (inlineView == null) {
      return;
    }
    final databaseController = DatabaseController(view: inlineView);
    _startListening(databaseController);
    final openDatabaseResult = await databaseController.open();
    openDatabaseResult.fold(
      (s) {
        databaseController.setIsLoading(false);
      },
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

  void _startListening(DatabaseController databaseController) {
    databaseController.addListener();
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
