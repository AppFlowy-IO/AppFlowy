part of 'app_bloc.dart';

@freezed
abstract class AppState implements _$AppState {
  const factory AppState({
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial() => AppState(
        apps: none(),
        successOrFailure: left(unit),
      );
}
