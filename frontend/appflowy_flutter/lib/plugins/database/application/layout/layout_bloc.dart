import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'layout_bloc.freezed.dart';

class DatabaseLayoutBloc
    extends Bloc<DatabaseLayoutEvent, DatabaseLayoutState> {
  DatabaseLayoutBloc({
    required String viewId,
    required DatabaseLayoutPB databaseLayout,
  }) : super(DatabaseLayoutState.initial(viewId, databaseLayout)) {
    on<DatabaseLayoutEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
          updateLayout: (DatabaseLayoutPB layout) {
            DatabaseViewBackendService.updateLayout(
              viewId: viewId,
              layout: layout,
            );
            emit(state.copyWith(databaseLayout: layout));
          },
        );
      },
    );
  }
}

@freezed
class DatabaseLayoutEvent with _$DatabaseLayoutEvent {
  const factory DatabaseLayoutEvent.initial() = _Initial;
  const factory DatabaseLayoutEvent.updateLayout(DatabaseLayoutPB layout) =
      _UpdateLayout;
}

@freezed
class DatabaseLayoutState with _$DatabaseLayoutState {
  const factory DatabaseLayoutState({
    required String viewId,
    required DatabaseLayoutPB databaseLayout,
  }) = _DatabaseLayoutState;

  factory DatabaseLayoutState.initial(
    String viewId,
    DatabaseLayoutPB databaseLayout,
  ) =>
      DatabaseLayoutState(
        viewId: viewId,
        databaseLayout: databaseLayout,
      );
}
