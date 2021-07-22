import 'package:app_flowy/home/domain/i_app.dart';
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
        iAppImpl.startWatching(
          updatedCallback: (name, desc) {},
          addViewCallback: (views) {},
        );
      },
      viewsReceived: (e) async* {
        yield state;
      },
    );
  }
}

@freezed
abstract class AppEvent with _$AppEvent {
  const factory AppEvent.initial() = _Initial;
  const factory AppEvent.viewsReceived(
      Either<List<View>, WorkspaceError> appsOrFail) = ViewsReceived;
}

@freezed
abstract class AppState implements _$AppState {
  const factory AppState({
    required bool isLoading,
    required Option<List<View>> views,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial() => AppState(
        isLoading: false,
        views: none(),
        successOrFailure: left(unit),
      );
}
