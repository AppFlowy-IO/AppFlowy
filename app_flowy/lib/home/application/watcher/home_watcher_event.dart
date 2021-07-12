part of 'home_watcher_bloc.dart';

@freezed
abstract class HomeWatcherEvent with _$HomeWatcherEvent {
  const factory HomeWatcherEvent.started(String workspaceId) = _Started;
  const factory HomeWatcherEvent.stop(String workspaceId) = _Stop;
}
