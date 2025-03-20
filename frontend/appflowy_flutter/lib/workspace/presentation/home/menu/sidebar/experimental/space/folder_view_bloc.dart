import 'dart:async';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/expand_views.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/services/workspace_http_services.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'folder_view_bloc.freezed.dart';

final ValueNotifier<int> refreshNotifier = ValueNotifier(0);

class FolderViewBloc extends Bloc<FolderViewEvent, FolderViewState> {
  FolderViewBloc({
    required this.view,
    required this.workspaceId,
    this.engagedInExpanding = false,
  })  : pageService = PageHttpService(workspaceId: workspaceId),
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
  final PageHttpService pageService;
  final bool engagedInExpanding;
  final String workspaceId;

  late ViewExpander expander;

  @override
  Future<void> close() async {
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
            // delete this event after integrate the websocket notification
            refreshNotifier.value = refreshNotifier.value + 1;
          },
          rename: (e) async {
            final response = await pageService.updatePageName(
              page: view,
              name: e.newName,
            );
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

            add(
              FolderViewEvent.viewDidUpdate(
                FlowyResult.success(FolderViewPB()),
              ),
            );
          },
          delete: (e) async {
            // unpublish the page and all its child pages if they are published
            await _unpublishPage(view);

            final response = await pageService.deletePage(
              page: view,
            );
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

            add(
              FolderViewEvent.viewDidUpdate(
                FlowyResult.success(FolderViewPB()),
              ),
            );
          },
          duplicate: (e) async {
            final response = await pageService.duplicatePage(
              page: view,
              suffix: ' (${LocaleKeys.menuAppHeader_pageNameSuffix.tr()})',
            );
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

            add(
              FolderViewEvent.viewDidUpdate(
                FlowyResult.success(FolderViewPB()),
              ),
            );
          },
          move: (value) async {
            final response = await pageService.movePage(
              page: view,
              newParentViewId: value.newParentId,
              prevViewId: value.prevId,
            );
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
            final response = await pageService.createPage(
              parentViewId: view.viewId,
              name: e.name,
              layout: e.layoutType,
            );
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

            add(
              FolderViewEvent.viewDidUpdate(
                FlowyResult.success(FolderViewPB()),
              ),
            );
          },
          viewUpdateChildView: (e) async {
            // do nothing
          },
          updateViewVisibility: (value) async {
            // do nothing
          },
          updateIcon: (value) async {
            final response = await pageService.updatePageIcon(
              page: view,
              icon: value.icon?.toViewIconPB(),
            );
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

            add(
              FolderViewEvent.viewDidUpdate(
                FlowyResult.success(FolderViewPB()),
              ),
            );
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
    await pageService.unpublishPage(page: view);
  }
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

  const factory FolderViewEvent.updateIcon(EmojiIconData? icon) = UpdateIcon;

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
