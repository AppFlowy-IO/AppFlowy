import 'dart:async';

import 'package:appflowy/workspace/application/workspace/workspace_sections_listener.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sidebar_sections_bloc.freezed.dart';

class SidebarSectionsBloc
    extends Bloc<SidebarSectionsEvent, SidebarSectionsState> {
  SidebarSectionsBloc() : super(SidebarSectionsState.initial()) {
    on<SidebarSectionsEvent>(
      (event, emit) async {
        await event.when(
          initial: (userProfile, workspaceId) async {
            _initial(userProfile, workspaceId);
            final (publicViews, privateViews) = await _getRootViews();
            emit(
              state.copyWith(
                publicViews: publicViews,
                privateViews: privateViews,
              ),
            );
          },
          createRootViewInSection: (name, section, desc, index) async {
            final result = await _workspaceService.createView(
              name: name,
              viewSection: section,
              desc: desc,
              index: index,
            );
            result.fold(
              (view) => emit(
                state.copyWith(
                  lastCreatedRootView: view,
                  createRootViewResult: FlowyResult.success(null),
                ),
              ),
              (error) {
                Log.error(error);
                emit(
                  state.copyWith(
                    createRootViewResult: FlowyResult.failure(error),
                  ),
                );
              },
            );
          },
          receiveSectionViewsUpdate: (sectionViews) async {
            final section = sectionViews.section;
            switch (section) {
              case ViewSectionPB.Public:
                emit(state.copyWith(publicViews: sectionViews.views));
              case ViewSectionPB.Private:
                emit(state.copyWith(privateViews: sectionViews.views));
                break;
              default:
                break;
            }
          },
          moveRootView: (fromIndex, toIndex, fromSection, toSection) async {
            final views = fromSection == ViewSectionPB.Public
                ? List<ViewPB>.from(state.publicViews)
                : List<ViewPB>.from(state.privateViews);
            if (fromIndex < 0 || fromIndex >= views.length) {
              Log.error(
                'Invalid fromIndex: $fromIndex, maxIndex: ${views.length - 1}',
              );
              return;
            }
            final view = views[fromIndex];
            final result = await _workspaceService.moveView(
              viewId: view.id,
              fromIndex: fromIndex,
              toIndex: toIndex,
            );
            result.fold(
              (value) {
                views.insert(toIndex, views.removeAt(fromIndex));
                emit(
                  state.copyWith(
                    publicViews: fromSection == ViewSectionPB.Public
                        ? views
                        : state.publicViews,
                    privateViews: fromSection == ViewSectionPB.Private
                        ? views
                        : state.privateViews,
                  ),
                );
              },
              (error) => Log.error(error),
            );
          },
        );
      },
    );
  }

  late WorkspaceService _workspaceService;
  WorkspaceSectionsListener? _listener;

  @override
  Future<void> close() async {
    await _listener?.stop();
    return super.close();
  }

  Future<(List<ViewPB>, List<ViewPB>)> _getRootViews() async {
    try {
      final publicViews = await _workspaceService.getPublicViews().getOrThrow();
      final privateViews =
          await _workspaceService.getPrivateViews().getOrThrow();
      return (publicViews, privateViews);
    } catch (e) {
      Log.error(e);
      return (<ViewPB>[], <ViewPB>[]);
    }
  }

  void _initial(UserProfilePB userProfile, String workspaceId) {
    _workspaceService = WorkspaceService(workspaceId: workspaceId);

    _listener?.stop();
    _listener = null;
    _listener = WorkspaceSectionsListener(
      user: userProfile,
      workspaceId: workspaceId,
    )..start(
        sectionChanged: (result) {
          result.fold(
            (s) => add(SidebarSectionsEvent.receiveSectionViewsUpdate(s)),
            (f) => Log.error('Failed to receive section views: $f'),
          );
        },
      );
  }
}

@freezed
class SidebarSectionsEvent with _$SidebarSectionsEvent {
  const factory SidebarSectionsEvent.initial(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Initial;
  const factory SidebarSectionsEvent.createRootViewInSection({
    required String name,
    required ViewSectionPB viewSection,
    String? desc,
    int? index,
  }) = _CreateRootViewInSection;
  const factory SidebarSectionsEvent.moveRootView({
    required int fromIndex,
    required int toIndex,
    required ViewSectionPB fromSection,
    required ViewSectionPB toSection,
  }) = _MoveRootView;
  const factory SidebarSectionsEvent.receiveSectionViewsUpdate(
    SectionViewsPB sectionViews,
  ) = _ReceiveSectionViewsUpdate;
}

@freezed
class SidebarSectionsState with _$SidebarSectionsState {
  const factory SidebarSectionsState({
    @Default([]) List<ViewPB> privateViews,
    @Default([]) List<ViewPB> publicViews,
    @Default(null) ViewPB? lastCreatedRootView,
    FlowyResult<void, FlowyError>? createRootViewResult,
  }) = _SidebarSectionsState;

  factory SidebarSectionsState.initial() => const SidebarSectionsState();
}
