import 'dart:async';

import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_view_section_bloc.freezed.dart';

class ViewSectionBloc extends Bloc<ViewSectionEvent, ViewSectionState> {
  void Function()? _viewsListener;
  void Function()? _selectedViewlistener;
  final AppViewDataContext _appViewData;

  ViewSectionBloc({
    required AppViewDataContext appViewData,
  })  : _appViewData = appViewData,
        super(ViewSectionState.initial(appViewData)) {
    on<ViewSectionEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _startListening();
        },
        setSelectedView: (_SetSelectedView value) {
          _setSelectView(value, emit);
        },
        didReceiveViewUpdated: (_DidReceiveViewUpdated value) {
          emit(state.copyWith(views: value.views));
        },
        moveView: (_MoveView value) async {
          _moveView(value, emit);
        },
      );
    });
  }

  void _startListening() {
    _viewsListener = _appViewData.addViewsChangeListener((views) {
      if (!isClosed) {
        add(ViewSectionEvent.didReceiveViewUpdated(views));
      }
    });
    _selectedViewlistener = _appViewData.addSelectedViewChangeListener((view) {
      if (!isClosed) {
        add(ViewSectionEvent.setSelectedView(view));
      }
    });
  }

  void _setSelectView(_SetSelectedView value, Emitter<ViewSectionState> emit) {
    if (state.views.contains(value.view)) {
      emit(state.copyWith(selectedView: value.view));
    } else {
      emit(state.copyWith(selectedView: null));
    }
  }

  Future<void> _moveView(
    _MoveView value,
    Emitter<ViewSectionState> emit,
  ) async {
    if (value.fromIndex < state.views.length) {
      final viewId = state.views[value.fromIndex].id;
      final views = List<ViewPB>.from(state.views);
      views.insert(value.toIndex, views.removeAt(value.fromIndex));
      emit(state.copyWith(views: views));

      final result = await ViewBackendService.moveView(
        viewId: viewId,
        fromIndex: value.fromIndex,
        toIndex: value.toIndex,
      );
      result.fold((l) => null, (err) => Log.error(err));
    }
  }

  @override
  Future<void> close() async {
    if (_selectedViewlistener != null) {
      _appViewData.removeSelectedViewListener(_selectedViewlistener!);
    }

    if (_viewsListener != null) {
      _appViewData.removeViewsListener(_viewsListener!);
    }

    return super.close();
  }
}

@freezed
class ViewSectionEvent with _$ViewSectionEvent {
  const factory ViewSectionEvent.initial() = _Initial;
  const factory ViewSectionEvent.setSelectedView(ViewPB? view) =
      _SetSelectedView;
  const factory ViewSectionEvent.moveView(int fromIndex, int toIndex) =
      _MoveView;
  const factory ViewSectionEvent.didReceiveViewUpdated(List<ViewPB> views) =
      _DidReceiveViewUpdated;
}

@freezed
class ViewSectionState with _$ViewSectionState {
  const factory ViewSectionState({
    required List<ViewPB> views,
    ViewPB? selectedView,
  }) = _ViewSectionState;

  factory ViewSectionState.initial(AppViewDataContext appViewData) =>
      ViewSectionState(
        views: appViewData.views,
        selectedView: appViewData.selectedView,
      );
}
