part of 'app_bloc.dart';

@freezed
abstract class AppState implements _$AppState {
  const factory AppState({
    required bool isLoading,
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial() => AppState(
        isLoading: false,
        apps: none(),
        successOrFailure: left(unit),
      );
}
