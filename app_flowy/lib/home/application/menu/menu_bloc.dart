import 'dart:async';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'menu_event.dart';
part 'menu_state.dart';
part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuState.initial());

  @override
  Stream<MenuState> mapEventToState(
    MenuEvent event,
  ) async* {
    yield* event.map(
      collapse: (e) async* {
        final isCollapse = state.isCollapse;
        yield state.copyWith(isCollapse: !isCollapse);
      },
      openPage: (e) async* {
        yield* _performActionOnOpenPage(e);
      },
      createApp: (e) async* {
        yield* _performActionOnCreateApp(e);
      },
    );
  }

  Stream<MenuState> _performActionOnOpenPage(_OpenPage e) async* {
    yield state.copyWith(pageContext: some(e.context));
  }

  Stream<MenuState> _performActionOnCreateApp(_CreateApp val) async* {
    yield state;
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
