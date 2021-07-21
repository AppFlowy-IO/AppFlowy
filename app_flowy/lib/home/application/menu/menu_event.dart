part of 'menu_bloc.dart';

@freezed
abstract class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(PageContext context) = OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = CreateApp;
  const factory MenuEvent.appsReceived(
      Either<List<App>, WorkspaceError> appsOrFail) = AppsReceived;
}
