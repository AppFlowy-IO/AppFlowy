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
  final ViewDataContext _appViewData;

  ViewSectionBloc({
    required ViewDataContext appViewData,
  })  : _appViewData = appViewData,
        super(ViewSectionState.initial(appViewData)) {
    on<ViewSectionEvent>((event, emit) async {
      await event.when(
        initial: () async {
          _startListening();
        },
        setSelectedView: (view) {
          emit(state.copyWith(selectedView: view));
        },
        didReceiveViewUpdated: (views) {
          emit(state.copyWith(views: views));
        },
        moveView: (fromIndex, toIndex) async {
          _moveView(fromIndex, toIndex, emit);
        },
      );
    });
  }

  void _startListening() {
    _viewsListener = _appViewData.onViewsChanged((views) {
      if (!isClosed) {
        add(ViewSectionEvent.didReceiveViewUpdated(views));
      }
    });
    _selectedViewlistener = _appViewData.onViewSelected((view) {
      if (!isClosed) {
        add(ViewSectionEvent.setSelectedView(view));
      }
    });
  }

  Future<void> _moveView(
    int fromIndex,
    int toIndex,
    Emitter<ViewSectionState> emit,
  ) async {
    if (fromIndex < state.views.length) {
      final viewId = state.views[fromIndex].id;
      final views = List<ViewPB>.from(state.views);
      views.insert(toIndex, views.removeAt(fromIndex));
      emit(state.copyWith(views: views));

      final result = await ViewBackendService.moveView(
        viewId: viewId,
        fromIndex: fromIndex,
        toIndex: toIndex,
      );
      result.fold((l) => null, (err) => Log.error(err));
    }
  }

  @override
  Future<void> close() async {
    if (_selectedViewlistener != null) {
      _appViewData.removeOnViewSelectedListener(_selectedViewlistener!);
    }

    if (_viewsListener != null) {
      _appViewData.removeOnViewChangedListener(_viewsListener!);
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

  factory ViewSectionState.initial(ViewDataContext appViewData) =>
      ViewSectionState(
        views: appViewData.views,
        selectedView: appViewData.selectedView,
      );
}
