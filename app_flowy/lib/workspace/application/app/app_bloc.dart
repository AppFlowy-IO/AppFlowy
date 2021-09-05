import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final IApp iAppImpl;
  AppBloc(this.iAppImpl) : super(AppState.initial());

  @override
  Stream<AppState> mapEventToState(
    AppEvent event,
  ) async* {
    yield* event.map(
      initial: (e) async* {
        yield* _fetchViews();
      },
      createView: (CreateView value) async* {
        iAppImpl.createView(
            name: value.name, desc: value.desc, viewType: value.viewType);
      },
    );
  }

  Stream<AppState> _fetchViews() async* {
    final viewsOrFailed = await iAppImpl.getViews();
    yield viewsOrFailed.fold(
      (apps) => state.copyWith(views: apps),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }
}

@freezed
abstract class AppEvent with _$AppEvent {
  const factory AppEvent.initial() = Initial;
  const factory AppEvent.createView(
      String name, String desc, ViewType viewType) = CreateView;
}

@freezed
abstract class AppState implements _$AppState {
  const factory AppState({
    required bool isLoading,
    required List<View>? views,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial() => AppState(
        isLoading: false,
        views: null,
        successOrFailure: left(unit),
      );
}
