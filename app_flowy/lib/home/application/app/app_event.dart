part of 'app_bloc.dart';

@freezed
abstract class AppEvent with _$AppEvent {
  const factory AppEvent.appsReceived(
      Either<List<App>, WorkspaceError> appsOrFail) = AppsReceived;
}
