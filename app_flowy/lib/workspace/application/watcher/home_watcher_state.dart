part of 'home_watcher_bloc.dart';

@freezed
abstract class HomeWatcherState with _$HomeWatcherState {
  const factory HomeWatcherState.initial() = _Initial;
  const factory HomeWatcherState.loading() = _Loading;
}
