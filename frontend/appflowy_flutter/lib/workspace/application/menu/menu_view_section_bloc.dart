import 'dart:async';

import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_view_section_bloc.freezed.dart';

class ViewSectionBloc extends Bloc<ViewSectionEvent, ViewSectionState> {
  void Function()? _viewsListener;
  void Function()? _selectedViewlistener;
  final AppViewDataContext _appViewData;
  late final AppBackendService _appService;

  ViewSectionBloc({
    required final AppViewDataContext appViewData,
  })  : _appService = AppBackendService(),
        _appViewData = appViewData,
        super(ViewSectionState.initial(appViewData)) {
    on<ViewSectionEvent>((final event, final emit) async {
      await event.map(
        initial: (final e) async {
          _startListening();
        },
        setSelectedView: (final _SetSelectedView value) {
          _setSelectView(value, emit);
        },
        didReceiveViewUpdated: (final _DidReceiveViewUpdated value) {
          emit(state.copyWith(views: value.views));
        },
        moveView: (final _MoveView value) async {
          _moveView(value, emit);
        },
      );
    });
  }

  void _startListening() {
    _viewsListener = _appViewData.addViewsChangeListener((final views) {
      if (!isClosed) {
        add(ViewSectionEvent.didReceiveViewUpdated(views));
      }
    });
    _selectedViewlistener = _appViewData.addSelectedViewChangeListener((final view) {
      if (!isClosed) {
        add(ViewSectionEvent.setSelectedView(view));
      }
    });
  }

  void _setSelectView(final _SetSelectedView value, final Emitter<ViewSectionState> emit) {
    if (state.views.contains(value.view)) {
      emit(state.copyWith(selectedView: value.view));
    } else {
      emit(state.copyWith(selectedView: null));
    }
  }

  Future<void> _moveView(
    final _MoveView value,
    final Emitter<ViewSectionState> emit,
  ) async {
    if (value.fromIndex < state.views.length) {
      final viewId = state.views[value.fromIndex].id;
      final views = List<ViewPB>.from(state.views);
      views.insert(value.toIndex, views.removeAt(value.fromIndex));
      emit(state.copyWith(views: views));

      final result = await _appService.moveView(
        viewId: viewId,
        fromIndex: value.fromIndex,
        toIndex: value.toIndex,
      );
      result.fold((final l) => null, (final err) => Log.error(err));
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
  const factory ViewSectionEvent.setSelectedView(final ViewPB? view) =
      _SetSelectedView;
  const factory ViewSectionEvent.moveView(final int fromIndex, final int toIndex) =
      _MoveView;
  const factory ViewSectionEvent.didReceiveViewUpdated(final List<ViewPB> views) =
      _DidReceiveViewUpdated;
}

@freezed
class ViewSectionState with _$ViewSectionState {
  const factory ViewSectionState({
    required final List<ViewPB> views,
    final ViewPB? selectedView,
  }) = _ViewSectionState;

  factory ViewSectionState.initial(final AppViewDataContext appViewData) =>
      ViewSectionState(
        views: appViewData.views,
        selectedView: appViewData.selectedView,
      );
}
