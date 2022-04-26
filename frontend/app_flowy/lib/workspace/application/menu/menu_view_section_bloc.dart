import 'dart:async';

import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_view_section_bloc.freezed.dart';

class ViewSectionBloc extends Bloc<ViewSectionEvent, ViewSectionState> {
  void Function()? _viewsListener;
  void Function()? _selectedViewlistener;
  final AppViewDataContext appViewData;

  ViewSectionBloc({
    required this.appViewData,
  }) : super(ViewSectionState.initial(appViewData)) {
    on<ViewSectionEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _startListening();
        },
        setSelectedView: (_SetSelectedView value) {
          if (state.views.contains(value.view)) {
            emit(state.copyWith(selectedView: value.view));
          } else {
            emit(state.copyWith(selectedView: null));
          }
        },
        didReceiveViewUpdated: (_DidReceiveViewUpdated value) {
          emit(state.copyWith(views: value.views));
        },
      );
    });
  }

  void _startListening() {
    _viewsListener = appViewData.addViewsChangeListener((views) {
      if (!isClosed) {
        add(ViewSectionEvent.didReceiveViewUpdated(views));
      }
    });
    _selectedViewlistener = appViewData.addSelectedViewChangeListener((view) {
      if (!isClosed) {
        add(ViewSectionEvent.setSelectedView(view));
      }
    });
  }

  @override
  Future<void> close() async {
    if (_selectedViewlistener != null) {
      appViewData.removeSelectedViewListener(_selectedViewlistener!);
    }

    if (_viewsListener != null) {
      appViewData.removeViewsListener(_viewsListener!);
    }

    return super.close();
  }
}

@freezed
class ViewSectionEvent with _$ViewSectionEvent {
  const factory ViewSectionEvent.initial() = _Initial;
  const factory ViewSectionEvent.setSelectedView(View? view) = _SetSelectedView;
  const factory ViewSectionEvent.didReceiveViewUpdated(List<View> views) = _DidReceiveViewUpdated;
}

@freezed
class ViewSectionState with _$ViewSectionState {
  const factory ViewSectionState({
    required List<View> views,
    View? selectedView,
  }) = _ViewSectionState;

  factory ViewSectionState.initial(AppViewDataContext appViewData) => ViewSectionState(
        views: appViewData.views,
        selectedView: appViewData.selectedView,
      );
}
