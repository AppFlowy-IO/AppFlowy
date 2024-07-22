import 'dart:async';

import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
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

class SidebarSection {
  const SidebarSection({
    required this.publicViews,
    required this.privateViews,
  });

  const SidebarSection.empty()
      : publicViews = const [],
        privateViews = const [];

  final List<ViewPB> publicViews;
  final List<ViewPB> privateViews;

  List<ViewPB> get views => publicViews + privateViews;

  SidebarSection copyWith({
    List<ViewPB>? publicViews,
    List<ViewPB>? privateViews,
  }) {
    return SidebarSection(
      publicViews: publicViews ?? this.publicViews,
      privateViews: privateViews ?? this.privateViews,
    );
  }
}

/// The [SidebarSectionsBloc] is responsible for
///   managing the root views in different sections of the workspace.
class SidebarSectionsBloc
    extends Bloc<SidebarSectionsEvent, SidebarSectionsState> {
  SidebarSectionsBloc() : super(SidebarSectionsState.initial()) {
    on<SidebarSectionsEvent>(
      (event, emit) async {
        await event.when(
          initial: (userProfile, workspaceId) async {
            _initial(userProfile, workspaceId);
            final sectionViews = await _getSectionViews();
            if (sectionViews != null) {
              final containsSpace = _containsSpace(sectionViews);
              emit(
                state.copyWith(
                  section: sectionViews,
                  containsSpace: containsSpace,
                ),
              );
            }
          },
          reset: (userProfile, workspaceId) async {
            _reset(userProfile, workspaceId);
            final sectionViews = await _getSectionViews();
            if (sectionViews != null) {
              final containsSpace = _containsSpace(sectionViews);
              emit(
                state.copyWith(
                  section: sectionViews,
                  containsSpace: containsSpace,
                ),
              );
            }
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
                Log.error('Failed to create root view: $error');
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
                emit(
                  state.copyWith(
                    containsSpace: state.containsSpace ||
                        sectionViews.views.any((view) => view.isSpace),
                    section: state.section.copyWith(
                      publicViews: sectionViews.views,
                    ),
                  ),
                );
              case ViewSectionPB.Private:
                emit(
                  state.copyWith(
                    containsSpace: state.containsSpace ||
                        sectionViews.views.any((view) => view.isSpace),
                    section: state.section.copyWith(
                      privateViews: sectionViews.views,
                    ),
                  ),
                );
                break;
              default:
                break;
            }
          },
          moveRootView: (fromIndex, toIndex, fromSection, toSection) async {
            final views = fromSection == ViewSectionPB.Public
                ? List<ViewPB>.from(state.section.publicViews)
                : List<ViewPB>.from(state.section.privateViews);
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
                var newState = state;
                if (fromSection == ViewSectionPB.Public) {
                  newState = newState.copyWith(
                    section: newState.section.copyWith(publicViews: views),
                  );
                } else if (fromSection == ViewSectionPB.Private) {
                  newState = newState.copyWith(
                    section: newState.section.copyWith(privateViews: views),
                  );
                }
                emit(newState);
              },
              (error) {
                Log.error('Failed to move root view: $error');
              },
            );
          },
          reload: (userProfile, workspaceId) async {
            _initial(userProfile, workspaceId);
            final sectionViews = await _getSectionViews();
            if (sectionViews != null) {
              final containsSpace = _containsSpace(sectionViews);
              emit(
                state.copyWith(
                  section: sectionViews,
                  containsSpace: containsSpace,
                ),
              );
              // try to open the fist view in public section or private section
              if (sectionViews.publicViews.isNotEmpty) {
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: sectionViews.publicViews.first.plugin(),
                  ),
                );
              } else if (sectionViews.privateViews.isNotEmpty) {
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: sectionViews.privateViews.first.plugin(),
                  ),
                );
              } else {
                getIt<TabsBloc>().add(
                  TabsEvent.openPlugin(
                    plugin: makePlugin(pluginType: PluginType.blank),
                  ),
                );
              }
            }
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
    _listener = null;
    return super.close();
  }

  ViewSectionPB? getViewSection(ViewPB view) {
    final publicViews = state.section.publicViews.map((e) => e.id);
    final privateViews = state.section.privateViews.map((e) => e.id);
    if (publicViews.contains(view.id)) {
      return ViewSectionPB.Public;
    } else if (privateViews.contains(view.id)) {
      return ViewSectionPB.Private;
    } else {
      return null;
    }
  }

  Future<SidebarSection?> _getSectionViews() async {
    try {
      final publicViews = await _workspaceService.getPublicViews().getOrThrow();
      final privateViews =
          await _workspaceService.getPrivateViews().getOrThrow();
      return SidebarSection(
        publicViews: publicViews,
        privateViews: privateViews,
      );
    } catch (e) {
      Log.error('Failed to get section views: $e');
      return null;
    }
  }

  bool _containsSpace(SidebarSection section) {
    return section.publicViews.any((view) => view.isSpace) ||
        section.privateViews.any((view) => view.isSpace);
  }

  void _initial(UserProfilePB userProfile, String workspaceId) {
    _workspaceService = WorkspaceService(workspaceId: workspaceId);

    _listener = WorkspaceSectionsListener(
      user: userProfile,
      workspaceId: workspaceId,
    )..start(
        sectionChanged: (result) {
          if (!isClosed) {
            result.fold(
              (s) => add(SidebarSectionsEvent.receiveSectionViewsUpdate(s)),
              (f) => Log.error('Failed to receive section views: $f'),
            );
          }
        },
      );
  }

  void _reset(UserProfilePB userProfile, String workspaceId) {
    _listener?.stop();
    _listener = null;

    _initial(userProfile, workspaceId);
  }
}

@freezed
class SidebarSectionsEvent with _$SidebarSectionsEvent {
  const factory SidebarSectionsEvent.initial(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Initial;
  const factory SidebarSectionsEvent.reset(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Reset;
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
  const factory SidebarSectionsEvent.reload(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Reload;
}

@freezed
class SidebarSectionsState with _$SidebarSectionsState {
  const factory SidebarSectionsState({
    required SidebarSection section,
    @Default(null) ViewPB? lastCreatedRootView,
    FlowyResult<void, FlowyError>? createRootViewResult,
    @Default(true) bool containsSpace,
  }) = _SidebarSectionsState;

  factory SidebarSectionsState.initial() => const SidebarSectionsState(
        section: SidebarSection.empty(),
      );
}
