import 'package:appflowy/workspace/application/panes/panes_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../panes.dart';

part 'panes_state.dart';

class PanesCubit extends Cubit<PanesState> {
  static final key = UniqueKey().toString();
  final PanesService panesService;
  PanesCubit()
      : panesService = PanesService(),
        super(PanesState.initial());

  void setActivePane(PaneNode activePane) {
    emit(state.copyWith(activePane: activePane));
  }

  void splitRight(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitRightHandler(
          state.root,
          state.activePane.paneId,
          view,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitDown(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitDownHandler(
          state.root,
          state.activePane.paneId,
          view,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitLeft(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitLeftHandler(
          state.root,
          state.activePane.paneId,
          view,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitUp(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitUpHandler(
          state.root,
          state.activePane.paneId,
          view,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void closePane(String paneId) {
    emit(
      state.copyWith(
        root: panesService.closePaneHandler(
          state.root,
          paneId,
          setActivePane,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }
}
