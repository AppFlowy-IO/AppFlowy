import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_listener.dart';
import 'package:appflowy/workspace/application/recent/recent_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

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
              final view = await _updateChildViews(result);
              if (!isClosed && view != null) {
                add(ViewEvent.viewUpdateChildView(view));
              }
            },
          );
          favoriteListener.start(
            favoritesUpdated: (result, isFavorite) {
              result.fold((error) {}, (result) {
                final current =
                    result.items.firstWhereOrNull((v) => v.id == state.view.id);
                if (current != null) {
                  add(ViewEvent.viewDidUpdate(left(current)));
                }
              });
            },
          );
          final isExpanded = await _getViewIsExpanded(view);
          emit(state.copyWith(isExpanded: isExpanded));
          await _loadViewsWhenExpanded(emit, isExpanded);
        },
        setIsEditing: (e) {
          emit(state.copyWith(isEditing: e.isEditing));
        },
        setIsExpanded: (e) async {
          if (e.isExpanded && !state.isExpanded) {
            await _loadViewsWhenExpanded(emit, true);
          } else {
            emit(state.copyWith(isExpanded: e.isExpanded));
          }
          await _setViewIsExpanded(view, e.isExpanded);
        },
        viewDidUpdate: (e) async {
          final result = await ViewBackendService.getView(
            view.id,
          );
          final view_ = result.fold((l) => l, (r) => null);
          e.result.fold(
            (view) async {
              // ignore child view changes because it only contains one level
              // children data.
              if (_isSameViewIgnoreChildren(view, state.view)) {
                // do nothing.
              }
              emit(
                state.copyWith(
                  view: view_ ?? view,
                  successOrFailure: left(unit),
                ),
              );
            },
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
              (l) {
                final view = state.view;
                view.freeze();
                final newView = view.rebuild(
                  (b) => b.name = e.newName,
                );
                return state.copyWith(
                  successOrFailure: left(unit),
                  view: newView,
                );
              },
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
        viewUpdateChildView: (e) async {
          emit(
            state.copyWith(
              view: e.result,
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
      emit(
        state.copyWith(
          view: view,
          isExpanded: false,
          isLoading: false,
        ),
      );
      return;
    }

    final viewsOrFailed =
        await ViewBackendService.getChildViews(viewId: state.view.id);

    viewsOrFailed.fold(
      (childViews) {
        state.view.freeze();
        final viewWithChildViews = state.view.rebuild((b) {
          b.childViews.clear();
          b.childViews.addAll(childViews);
        });
        emit(
          state.copyWith(
            view: viewWithChildViews,
            isExpanded: true,
            isLoading: false,
          ),
        );
      },
      (error) => emit(
        state.copyWith(
          successOrFailure: right(error),
          isExpanded: true,
          isLoading: false,
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

  Future<ViewPB?> _updateChildViews(
    ChildViewUpdatePB update,
  ) async {
    Log.debug(
      'received child views of ${this.view.name}(${this.view.id}) update, $update',
    );
    if (update.createChildViews.isNotEmpty) {
      // refresh the child views if the update isn't empty
      // because there's no info to get the inserted index.
      assert(update.parentViewId == this.view.id);
      final view = await ViewBackendService.getView(
        update.parentViewId,
      );
      return view.fold((l) => l, (r) => null);
    }

    final view = state.view;
    view.freeze();
    final childViews = [...view.childViews];
    if (update.deleteChildViews.isNotEmpty) {
      childViews.removeWhere((v) => update.deleteChildViews.contains(v.id));
      return view.rebuild((p0) {
        p0.childViews.clear();
        p0.childViews.addAll(childViews);
      });
    }

    if (update.updateChildViews.isNotEmpty) {
      final view = await ViewBackendService.getView(
        update.parentViewId,
      );
      final childViews = view.fold((l) => l.childViews, (r) => []);
      bool isSameOrder = true;
      if (childViews.length == update.updateChildViews.length) {
        for (var i = 0; i < childViews.length; i++) {
          if (childViews[i].id != update.updateChildViews[i].id) {
            isSameOrder = false;
            break;
          }
        }
      } else {
        isSameOrder = false;
      }
      if (!isSameOrder) {
        return view.fold((l) => l, (r) => null);
      }
    }

    return null;
  }

  bool _isSameViewIgnoreChildren(ViewPB from, ViewPB to) {
    return _hash(from) == _hash(to);
  }

  int _hash(ViewPB view) => Object.hash(
        view.id,
        view.name,
        view.createTime,
        view.icon,
        view.parentViewId,
        view.layout,
      );
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
  const factory ViewEvent.viewUpdateChildView(ViewPB result) =
      ViewUpdateChildView;
}

@freezed
class ViewState with _$ViewState {
  const factory ViewState({
    required ViewPB view,
    required bool isEditing,
    required bool isExpanded,
    required Either<Unit, FlowyError> successOrFailure,
    @Default(true) bool isLoading,
    @Default(null) ViewPB? lastCreatedView,
  }) = _ViewState;

  factory ViewState.init(ViewPB view) => ViewState(
        view: view,
        isExpanded: false,
        isEditing: false,
        successOrFailure: left(unit),
        lastCreatedView: null,
        isLoading: true,
      );
}
