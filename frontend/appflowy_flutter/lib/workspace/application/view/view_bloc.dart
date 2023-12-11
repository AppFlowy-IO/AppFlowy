import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_listener.dart';
import 'package:appflowy/workspace/application/recent/recent_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'view_bloc.freezed.dart';

class ViewBloc extends Bloc<ViewEvent, ViewState> {
  final ViewBackendService viewBackendSvc;
  final ViewListener listener;
  final FavoriteListener favoriteListener;
  final ViewPB view;

  ViewBloc({
    required this.view,
  })  : viewBackendSvc = ViewBackendService(),
        listener = ViewListener(viewId: view.id),
        favoriteListener = FavoriteListener(),
        super(ViewState.init(view)) {
    on<ViewEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          listener.start(
            onViewUpdated: (result) {
              add(ViewEvent.viewDidUpdate(left(result)));
            },
            onViewChildViewsUpdated: (result) async {
              final view = await ViewBackendService.getView(
                result.parentViewId,
              );
              view.fold(
                (view) => add(ViewEvent.viewDidUpdate(left(view))),
                (error) => add(ViewEvent.viewDidUpdate(right(error))),
              );
            },
          );
          favoriteListener.start(
            favoritesUpdated: (result, isFavorite) {
              result.fold((error) {}, (result) {
                final current =
                    result.items.firstWhereOrNull((v) => v.id == view.id);
                if (current != null) {
                  add(ViewEvent.viewDidUpdate(left(current)));
                }
              });
            },
          );
          final isExpanded = await _getViewIsExpanded(view);
          await _loadViewsWhenExpanded(emit, isExpanded);
        },
        setIsEditing: (e) {
          emit(state.copyWith(isEditing: e.isEditing));
        },
        setIsExpanded: (e) async {
          if (e.isExpanded) {
            await _loadViewsWhenExpanded(emit, true);
          } else {
            emit(state.copyWith(isExpanded: e.isExpanded));
          }
          await _setViewIsExpanded(view, e.isExpanded);
        },
        viewDidUpdate: (e) {
          e.result.fold(
            (view) => emit(
              state.copyWith(
                view: view,
                childViews: view.childViews,
                successOrFailure: left(unit),
              ),
            ),
            (error) => emit(
              state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        rename: (e) async {
          final result = await ViewBackendService.updateView(
            viewId: view.id,
            name: e.newName,
          );
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        delete: (e) async {
          final result = await ViewBackendService.delete(viewId: view.id);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
          RecentService().updateRecentViews([view.id], false);
        },
        duplicate: (e) async {
          final result = await ViewBackendService.duplicate(view: view);
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        move: (value) async {
          final result = await ViewBackendService.moveViewV2(
            viewId: value.from.id,
            newParentId: value.newParentId,
            prevViewId: value.prevId,
          );
          emit(
            result.fold(
              (l) => state.copyWith(successOrFailure: left(unit)),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
        createView: (e) async {
          final result = await ViewBackendService.createView(
            parentViewId: view.id,
            name: e.name,
            desc: '',
            layoutType: e.layoutType,
            initialDataBytes: null,
            ext: {},
            openAfterCreate: e.openAfterCreated,
          );

          emit(
            result.fold(
              (view) => state.copyWith(
                lastCreatedView: view,
                successOrFailure: left(unit),
              ),
              (error) => state.copyWith(successOrFailure: right(error)),
            ),
          );
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    await favoriteListener.stop();
    return super.close();
  }

  Future<void> _loadViewsWhenExpanded(
    Emitter<ViewState> emit,
    bool isExpanded,
  ) async {
    if (!isExpanded) {
      return;
    }
    if (state.childViews.isNotEmpty) {
      // notify the old child views
      emit(
        state.copyWith(
          childViews: state.childViews,
          isExpanded: true,
        ),
      );
    }
    final viewsOrFailed =
        await ViewBackendService.getChildViews(viewId: state.view.id);
    viewsOrFailed.fold(
      (childViews) => emit(
        state.copyWith(
          childViews: childViews,
          isExpanded: true,
        ),
      ),
      (error) => emit(
        state.copyWith(
          successOrFailure: right(error),
          isExpanded: true,
        ),
      ),
    );
  }

  Future<void> _setViewIsExpanded(ViewPB view, bool isExpanded) async {
    final result = await getIt<KeyValueStorage>().get(KVKeys.expandedViews);
    final map = result.fold(
      () => {},
      (r) => jsonDecode(r),
    );
    if (isExpanded) {
      map[view.id] = true;
    } else {
      map.remove(view.id);
    }
    await getIt<KeyValueStorage>().set(KVKeys.expandedViews, jsonEncode(map));
  }

  Future<bool> _getViewIsExpanded(ViewPB view) {
    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      return result.fold(() => false, (r) {
        final map = jsonDecode(r);
        return map[view.id] ?? false;
      });
    });
  }
}

@freezed
class ViewEvent with _$ViewEvent {
  const factory ViewEvent.initial() = Initial;
  const factory ViewEvent.setIsEditing(bool isEditing) = SetEditing;
  const factory ViewEvent.setIsExpanded(bool isExpanded) = SetIsExpanded;
  const factory ViewEvent.rename(String newName) = Rename;
  const factory ViewEvent.delete() = Delete;
  const factory ViewEvent.duplicate() = Duplicate;
  const factory ViewEvent.move(
    ViewPB from,
    String newParentId,
    String? prevId,
  ) = Move;
  const factory ViewEvent.createView(
    String name,
    ViewLayoutPB layoutType, {
    /// open the view after created
    @Default(true) bool openAfterCreated,
  }) = CreateView;
  const factory ViewEvent.viewDidUpdate(Either<ViewPB, FlowyError> result) =
      ViewDidUpdate;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required ViewPB view,
    required List<ViewPB> childViews,
    required bool isEditing,
    required bool isExpanded,
    required Either<Unit, FlowyError> successOrFailure,
    @Default(null) ViewPB? lastCreatedView,
  }) = _ViewState;

  factory ViewState.init(ViewPB view) => ViewState(
        view: view,
        childViews: view.childViews,
        isExpanded: false,
        isEditing: false,
        successOrFailure: left(unit),
        lastCreatedView: null,
      );
}
