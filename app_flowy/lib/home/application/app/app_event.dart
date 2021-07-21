part of 'app_bloc.dart';

@freezed
abstract class AppEvent with _$AppEvent {
  const factory AppEvent.initial() = _Initial;
  const factory AppEvent.viewsReceived(
      Either<List<View>, WorkspaceError> appsOrFail) = ViewsReceived;
}
