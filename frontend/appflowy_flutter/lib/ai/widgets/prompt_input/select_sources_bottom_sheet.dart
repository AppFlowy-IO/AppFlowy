import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/flowy_search_text_field.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_bloc.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_sources_cubit.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'select_sources_menu.dart';

class PromptInputMobileSelectSourcesButton extends StatefulWidget {
  const PromptInputMobileSelectSourcesButton({
    super.key,
    required this.onUpdateSelectedSources,
  });

  final void Function(List<String>) onUpdateSelectedSources;

  @override
  State<PromptInputMobileSelectSourcesButton> createState() =>
      _PromptInputMobileSelectSourcesButtonState();
}

class _PromptInputMobileSelectSourcesButtonState
    extends State<PromptInputMobileSelectSourcesButton> {
  late final cubit = ChatSettingsCubit();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.updateSelectedSources(
        context.read<ChatBloc>().state.selectedSourceIds,
      );
    });
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        final userProfile = context.read<UserWorkspaceBloc>().userProfile;
        final workspaceId = state.currentWorkspace?.workspaceId ?? '';
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              key: ValueKey(workspaceId),
              create: (context) => SpaceBloc(
                userProfile: userProfile,
                workspaceId: workspaceId,
              )..add(const SpaceEvent.initial(openFirstPage: false)),
            ),
            BlocProvider.value(
              value: cubit,
            ),
          ],
          child: BlocBuilder<SpaceBloc, SpaceState>(
            builder: (context, state) {
              return BlocListener<ChatBloc, ChatState>(
                listener: (context, state) {
                  cubit
                    ..updateSelectedSources(state.selectedSourceIds)
                    ..updateSelectedStatus();
                },
                child: FlowyButton(
                  margin: const EdgeInsetsDirectional.fromSTEB(4, 6, 2, 6),
                  expandText: false,
                  text: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        FlowySvgs.ai_page_s,
                        color: Theme.of(context).iconTheme.color,
                        size: const Size.square(20.0),
                      ),
                      FlowySvg(
                        FlowySvgs.ai_source_drop_down_s,
                        color: Theme.of(context).hintColor,
                        size: const Size.square(10),
                      ),
                    ],
                  ),
                  onTap: () async {
                    context
                        .read<ChatSettingsCubit>()
                        .refreshSources(state.spaces, state.currentSpace);
                    await showMobileBottomSheet<void>(
                      context,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      maxChildSize: 0.98,
                      enableDraggableScrollable: true,
                      scrollableWidgetBuilder: (_, scrollController) {
                        return Expanded(
                          child: BlocProvider.value(
                            value: cubit,
                            child: _MobileSelectSourcesSheetBody(
                              scrollController: scrollController,
                            ),
                          ),
                        );
                      },
                      builder: (context) => const SizedBox.shrink(),
                    );
                    if (context.mounted) {
                      widget.onUpdateSelectedSources(cubit.selectedSourceIds);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MobileSelectSourcesSheetBody extends StatefulWidget {
  const _MobileSelectSourcesSheetBody({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  State<_MobileSelectSourcesSheetBody> createState() =>
      _MobileSelectSourcesSheetBodyState();
}

class _MobileSelectSourcesSheetBodyState
    extends State<_MobileSelectSourcesSheetBody> {
  final textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.scrollController,
      shrinkWrap: true,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _Header(
            child: ColoredBox(
              color: Theme.of(context).cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DragHandle(),
                  SizedBox(
                    height: 44.0,
                    child: Center(
                      child: FlowyText.medium(
                        LocaleKeys.chat_selectSources.tr(),
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: SizedBox(
                      height: 44.0,
                      child: FlowySearchTextField(
                        controller: textController,
                        onChanged: (value) => context
                            .read<ChatSettingsCubit>()
                            .updateFilter(value),
                      ),
                    ),
                  ),
                  const Divider(height: 0.5, thickness: 0.5),
                ],
              ),
            ),
          ),
        ),
        BlocBuilder<ChatSettingsCubit, ChatSettingsState>(
          builder: (context, state) {
            final sources = state.visibleSources
                .where((e) => e.ignoreStatus != IgnoreViewType.hide);
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: sources.length,
                (context, index) {
                  final source = sources.elementAt(index);
                  return ChatSourceTreeItem(
                    key: ValueKey(
                      'visible_select_sources_tree_item_${source.view.id}',
                    ),
                    chatSource: source,
                    level: 0,
                    isDescendentOfSpace: source.view.isSpace,
                    isSelectedSection: false,
                    onSelected: (chatSource) {
                      context
                          .read<ChatSettingsCubit>()
                          .toggleSelectedStatus(chatSource);
                    },
                    height: 40.0,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Header extends SliverPersistentHeaderDelegate {
  const _Header({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 120.5;

  @override
  double get minExtent => 120.5;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
