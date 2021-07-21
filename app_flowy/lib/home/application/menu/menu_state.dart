part of 'menu_bloc.dart';

@freezed
abstract class MenuState implements _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required Option<PageContext> pageContext,
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        pageContext: none(),
        apps: none(),
        successOrFailure: left(unit),
      );
}
