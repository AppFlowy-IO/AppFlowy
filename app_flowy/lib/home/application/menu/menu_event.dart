part of 'menu_bloc.dart';

@freezed
abstract class MenuEvent with _$MenuEvent {
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(PageContext context) = _OpenPage;
  const factory MenuEvent.createApp(String appName) = _CreateApp;
}
