import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'layout_service.dart';
part 'layout_bloc.freezed.dart';

class DatabaseLayoutBloc
    extends Bloc<DatabaseLayoutEvent, DatabaseLayoutState> {
  final DatabaseLayoutBackendService layoutService;

  DatabaseLayoutBloc({
    required String viewId,
    required DatabaseLayoutPB databaseLayout,
  })  : layoutService = DatabaseLayoutBackendService(viewId),
        super(DatabaseLayoutState.initial(viewId, databaseLayout)) {
    on<DatabaseLayoutEvent>(
      (event, emit) async {
        event.when(
          initial: () {},
          updateLayout: (DatabaseLayoutPB layout) {
            layoutService.updateLayout(
              fieldId: viewId,
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
