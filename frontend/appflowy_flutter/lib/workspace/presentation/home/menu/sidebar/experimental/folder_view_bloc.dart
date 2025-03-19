import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/expand_views.dart';
import 'package:appflowy/workspace/application/favorite/favorite_listener.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_v2_bloc.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'folder_view_bloc.freezed.dart';

class FolderViewBloc extends Bloc<FolderViewEvent, FolderViewState> {
  FolderViewBloc({
    required this.view,
    required this.currentWorkspaceId,
    this.shouldLoadChildViews = true,
    this.engagedInExpanding = false,
  })  : viewBackendSvc = ViewBackendService(),
        listener = ViewListener(viewId: view.viewId),
        favoriteListener = FavoriteListener(),
        super(FolderViewState.init(view)) {
    _dispatch();
    if (engagedInExpanding) {
      expander = ViewExpander(
        () => state.isExpanded,
        () => add(const FolderViewEvent.setIsExpanded(true)),
      );
      getIt<ViewExpanderRegistry>().register(view.viewId, expander);
    }
  }

  final FolderViewPB view;
  final ViewBackendService viewBackendSvc;
  final ViewListener listener;
  final FavoriteListener favoriteListener;
  final bool shouldLoadChildViews;
  final bool engagedInExpanding;
  final String currentWorkspaceId;

  late ViewExpander expander;

  @override
  Future<void> close() async {
    await listener.stop();
    await favoriteListener.stop();
    if (engagedInExpanding) {
      getIt<ViewExpanderRegistry>().unregister(view.viewId, expander);
    }
    return super.close();
  }

  void _dispatch() {
    on<FolderViewEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            final isExpanded = await _getViewIsExpanded(view);
            emit(
              state.copyWith(
                isExpanded: isExpanded,
                view: view,
              ),
            );
          },
          setIsEditing: (e) {
            emit(
              state.copyWith(isEditing: e.isEditing),
            );
          },
          setIsExpanded: (e) async {
            emit(state.copyWith(isExpanded: e.isExpanded));

            await _setViewIsExpanded(view, e.isExpanded);
          },
          viewDidUpdate: (e) async {
            // do nothing
          },
          rename: (e) async {
            // keep the original icon and isLocked status
            final payload = UpdatePagePayloadPB(
              workspaceId: currentWorkspaceId,
              viewId: view.viewId,
              icon: view.icon,
              isLocked: view.isLocked,
              name: e.newName,
            );
            final response = await FolderEventUpdatePage(payload).send();
            emit(
              response.fold(
                (l) {
                  final view = state.view;
                  view.freeze();
                  final newView = view.rebuild(
                    (b) => b.name = e.newName,
                  );
                  Log.info('rename view: ${newView.viewId} to ${newView.name}');
                  return state.copyWith(
                    successOrFailure: FlowyResult.success(null),
                    view: newView,
                  );
                },
                (error) {
                  Log.error('rename view failed: $error');
                  return state.copyWith(
                    successOrFailure: FlowyResult.failure(error),
                  );
                },
              ),
            );
          },
          delete: (e) async {
            // unpublish the page and all its child pages if they are published
            await _unpublishPage(view);

            final request = MovePageToTrashPayloadPB(
              workspaceId: currentWorkspaceId,
              viewId: view.viewId,
            );
            final response = await FolderEventMovePageToTrash(request).send();
            final newState = response.fold(
              (folderView) => state.copyWith(
                successOrFailure: FlowyResult.success(null),
                isDeleted: true,
              ),
              (error) => state.copyWith(
                successOrFailure: FlowyResult.failure(error),
              ),
            );

            emit(newState);
            await getIt<CachedRecentService>().updateRecentViews(
              [view.viewId],
              false,
            );
          },
          duplicate: (e) async {
            final request = DuplicatePagePayloadPB(
              workspaceId: currentWorkspaceId,
              viewId: view.viewId,
              suffix: ' (${LocaleKeys.menuAppHeader_pageNameSuffix.tr()})',
            );
            final response = await FolderEventDuplicatePage(request).send();
            emit(
              response.fold(
                (l) => state.copyWith(
                  successOrFailure: FlowyResult.success(null),
                ),
                (error) => state.copyWith(
                  successOrFailure: FlowyResult.failure(error),
                ),
              ),
            );
          },
          move: (value) async {
            final request = MovePagePayloadPB(
              workspaceId: currentWorkspaceId,
              viewId: value.from.viewId,
              newParentViewId: value.newParentId,
              prevViewId: value.prevId,
            );
            final response = await FolderEventMovePage(request).send();
            emit(
              response.fold(
                (l) => state.copyWith(
                  successOrFailure: FlowyResult.success(null),
                ),
                (error) => state.copyWith(
                  successOrFailure: FlowyResult.failure(error),
                ),
              ),
            );
          },
          createView: (e) async {
            final request = CreatePagePayloadPB(
              workspaceId: currentWorkspaceId,
              parentViewId: view.viewId,
              name: e.name,
              layout: e.layoutType,
            );
            final response = await FolderEventCreatePage(request).send();
            emit(
              response.fold(
                (view) => state.copyWith(
                  successOrFailure: FlowyResult.success(null),
                ),
                (error) => state.copyWith(
                  successOrFailure: FlowyResult.failure(error),
                ),
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
          updateViewVisibility: (value) async {
            // do nothing
          },
          updateIcon: (value) async {
            // fixme: update icon
          },
          collapseAllPages: (value) async {
            for (final childView in view.children) {
              await _setViewIsExpanded(childView, false);
            }
            add(const FolderViewEvent.setIsExpanded(false));
          },
          unpublish: (value) async {
            if (value.sync) {
              await _unpublishPage(view);
            } else {
              unawaited(_unpublishPage(view));
            }
          },
        );
      },
    );
  }

  Future<void> _setViewIsExpanded(FolderViewPB view, bool isExpanded) async {
    final result = await getIt<KeyValueStorage>().get(KVKeys.expandedViews);
    final Map map;
    if (result != null) {
      map = jsonDecode(result);
    } else {
      map = {};
    }
    if (isExpanded) {
      map[view.viewId] = true;
    } else {
      map.remove(view.viewId);
    }
    await getIt<KeyValueStorage>().set(KVKeys.expandedViews, jsonEncode(map));
  }

  Future<bool> _getViewIsExpanded(FolderViewPB view) {
    return getIt<KeyValueStorage>().get(KVKeys.expandedViews).then((result) {
      if (result == null) {
        return false;
      }
      final map = jsonDecode(result);
      return map[view.viewId] ?? false;
    });
  }

  // unpublish the page and all its child pages
  Future<void> _unpublishPage(FolderViewPB view) async {
    final publishedPages =
        view.children.where((view) => view.isPublished).toList();
    if (view.isPublished) {
      publishedPages.add(view);
    }

    await Future.wait(
      publishedPages.map((view) async {
        Log.info('unpublishing page: ${view.viewId}, ${view.name}');
        await ViewBackendService.unpublish(view.viewPB);
      }),
    );
  }

  bool _isSameViewIgnoreChildren(FolderViewPB from, FolderViewPB to) {
    return _hash(from) == _hash(to);
  }

  int _hash(FolderViewPB view) => Object.hash(
        view.viewId,
        view.name,
        view.createdAt,
        view.icon,
        view.layout,
      );
}

@freezed
class FolderViewEvent with _$FolderViewEvent {
  const factory FolderViewEvent.initial() = Initial;

  const factory FolderViewEvent.setIsEditing(bool isEditing) = SetEditing;

  const factory FolderViewEvent.setIsExpanded(bool isExpanded) = SetIsExpanded;

  const factory FolderViewEvent.rename(String newName) = Rename;

  const factory FolderViewEvent.delete() = Delete;

  const factory FolderViewEvent.duplicate() = Duplicate;

  const factory FolderViewEvent.move(
    FolderViewPB from,
    String newParentId,
    String? prevId,
    ViewSectionPB? fromSection,
    ViewSectionPB? toSection,
  ) = Move;

  const factory FolderViewEvent.createView(
    String name,
    ViewLayoutPB layoutType, {
    /// open the view after created
    @Default(true) bool openAfterCreated,
    ViewSectionPB? section,
  }) = CreateView;

  const factory FolderViewEvent.viewDidUpdate(
    FlowyResult<FolderViewPB, FlowyError> result,
  ) = ViewDidUpdate;

  const factory FolderViewEvent.viewUpdateChildView(FolderViewPB result) =
      ViewUpdateChildView;

  const factory FolderViewEvent.updateViewVisibility(
    FolderViewPB view,
    bool isPublic,
  ) = UpdateViewVisibility;

  const factory FolderViewEvent.updateIcon(String? icon) = UpdateIcon;

  const factory FolderViewEvent.collapseAllPages() = CollapseAllPages;

  // this event will unpublish the page and all its child pages if they are published
  const factory FolderViewEvent.unpublish({required bool sync}) = Unpublish;
}

@freezed
class FolderViewState with _$FolderViewState {
  const factory FolderViewState({
    required FolderViewPB view,
    required bool isEditing,
    required bool isExpanded,
    required FlowyResult<void, FlowyError> successOrFailure,
    @Default(false) bool isDeleted,
    @Default(true) bool isLoading,
    @Default(null) FolderViewPB? lastCreatedView,
  }) = _FolderViewState;

  factory FolderViewState.init(FolderViewPB view) => FolderViewState(
        view: view,
        isExpanded: false,
        isEditing: false,
        successOrFailure: FlowyResult.success(null),
      );
}
