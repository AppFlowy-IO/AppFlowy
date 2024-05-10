part of 'tabs_bloc.dart';

@freezed
class TabsEvent with _$TabsEvent {
  const factory TabsEvent.moveTab() = _MoveTab;
  const factory TabsEvent.closeTab(String pluginId) = _CloseTab;
  const factory TabsEvent.closeCurrentTab() = _CloseCurrentTab;
  const factory TabsEvent.selectTab(int index) = _SelectTab;
  const factory TabsEvent.openTab({
    required Plugin plugin,
    required ViewPB view,
  }) = _OpenTab;
  const factory TabsEvent.openPlugin({
    required Plugin plugin,
    ViewPB? view,
    @Default(true) bool setLatest,
  }) = _OpenPlugin;
}
