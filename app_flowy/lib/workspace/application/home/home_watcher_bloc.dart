import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_watcher_bloc.freezed.dart';

class HomeWatcherBloc extends Bloc<HomeWatcherEvent, HomeWatcherState> {
  HomeWatcherBloc() : super(const HomeWatcherState.initial());

  @override
  Stream<HomeWatcherState> mapEventToState(
    HomeWatcherEvent event,
  ) async* {
    yield state;
  }
}

@freezed
abstract class HomeWatcherEvent with _$HomeWatcherEvent {
  const factory HomeWatcherEvent.started(String workspaceId) = _Started;
  const factory HomeWatcherEvent.stop(String workspaceId) = _Stop;
}

@freezed
abstract class HomeWatcherState with _$HomeWatcherState {
  const factory HomeWatcherState.initial() = _Initial;
  const factory HomeWatcherState.loading() = _Loading;
}
