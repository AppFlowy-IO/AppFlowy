import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_watcher_event.dart';
part 'home_watcher_state.dart';
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
