import 'dart:async';

import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tab_menu_bloc.freezed.dart';

class TabMenuBloc extends Bloc<TabMenuEvent, TabMenuState> {
  TabMenuBloc({required this.viewId}) : super(const TabMenuState.isLoading()) {
    _fetchView();
    _dispatch();
  }

  final String viewId;
  ViewPB? view;

  void _dispatch() {
    on<TabMenuEvent>(
      (event, emit) async {
        await event.when(
          error: (error) async => emit(const TabMenuState.isError()),
          fetchedView: (view) async =>
              emit(TabMenuState.isReady(isFavorite: view.isFavorite)),
          toggleFavorite: () async {
            final didToggle = await ViewBackendService.favorite(viewId: viewId);
            if (didToggle.isSuccess) {
              final isFavorite = state.maybeMap(
                isReady: (s) => s.isFavorite,
                orElse: () => null,
              );
              if (isFavorite != null) {
                emit(TabMenuState.isReady(isFavorite: !isFavorite));
              }
            }
          },
        );
      },
    );
  }

  Future<void> _fetchView() async {
    final viewOrFailure = await ViewBackendService.getView(viewId);
    viewOrFailure.fold(
      (view) {
        this.view = view;
        add(TabMenuEvent.fetchedView(view));
      },
      (error) {
        Log.error(error);
        add(TabMenuEvent.error(error));
      },
    );
  }
}

@freezed
class TabMenuEvent with _$TabMenuEvent {
  const factory TabMenuEvent.error(FlowyError error) = _Error;
  const factory TabMenuEvent.fetchedView(ViewPB view) = _FetchedView;
  const factory TabMenuEvent.toggleFavorite() = _ToggleFavorite;
}

@freezed
class TabMenuState with _$TabMenuState {
  const factory TabMenuState.isLoading() = _IsLoading;

  /// This will only be the state in case fetching the view failed.
  ///
  /// One such case can be from when a View is in the trash, as such we can disable
  /// certain options in the TabMenu such as the favorite option.
  ///
  const factory TabMenuState.isError() = _IsError;

  const factory TabMenuState.isReady({required bool isFavorite}) = _IsReady;
}
