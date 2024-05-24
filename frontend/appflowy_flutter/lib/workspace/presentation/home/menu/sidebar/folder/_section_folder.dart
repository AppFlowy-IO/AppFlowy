import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_folder_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SectionFolder extends StatefulWidget {
  const SectionFolder({
    super.key,
    required this.title,
    required this.spaceType,
    required this.views,
    this.isHoverEnabled = true,
    required this.expandButtonTooltip,
    required this.addButtonTooltip,
  });

  final String title;
  final FolderSpaceType spaceType;
  final List<ViewPB> views;
  final bool isHoverEnabled;
  final String expandButtonTooltip;
  final String addButtonTooltip;

  @override
  State<SectionFolder> createState() => _SectionFolderState();
}

class _SectionFolderState extends State<SectionFolder> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: BlocProvider<FolderBloc>(
        create: (context) => FolderBloc(type: widget.spaceType)
          ..add(
            const FolderEvent.initial(),
          ),
        child: BlocBuilder<FolderBloc, FolderState>(
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(context),
                // Pages
                const VSpace(4.0),
                ..._buildViews(context, state, isHovered),
                // Add a placeholder if there are no views
                _buildDraggablePlaceholder(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FolderHeader(
      title: widget.title,
      expandButtonTooltip: widget.expandButtonTooltip,
      addButtonTooltip: widget.addButtonTooltip,
      onPressed: () =>
          context.read<FolderBloc>().add(const FolderEvent.expandOrUnExpand()),
      onAdded: () {
        createViewAndShowRenameDialogIfNeeded(
          context,
          LocaleKeys.newPageText.tr(),
          (viewName, _) {
            if (viewName.isNotEmpty) {
              context.read<SidebarSectionsBloc>().add(
                    SidebarSectionsEvent.createRootViewInSection(
                      name: viewName,
                      index: 0,
                      viewSection: widget.spaceType.toViewSectionPB,
                    ),
                  );

              context.read<FolderBloc>().add(
                    const FolderEvent.expandOrUnExpand(
                      isExpanded: true,
                    ),
                  );
            }
          },
        );
      },
    );
  }

  Iterable<Widget> _buildViews(
    BuildContext context,
    FolderState state,
    ValueNotifier<bool> isHovered,
  ) {
    if (!state.isExpanded) {
      return [];
    }

    return widget.views.map(
      (view) => ViewItem(
        key: ValueKey('${widget.spaceType.name} ${view.id}'),
        spaceType: widget.spaceType,
        isFirstChild: view.id == widget.views.first.id,
        view: view,
        level: 0,
        leftPadding: HomeSpaceViewSizes.leftPadding,
        isFeedback: false,
        isHovered: isHovered,
        onSelected: (viewContext, view) {
          if (HardwareKeyboard.instance.isControlPressed) {
            context.read<TabsBloc>().openTab(view);
          }

          context.read<TabsBloc>().openPlugin(view);
        },
        onTertiarySelected: (viewContext, view) =>
            context.read<TabsBloc>().openTab(view),
        isHoverEnabled: widget.isHoverEnabled,
      ),
    );
  }

  Widget _buildDraggablePlaceholder(BuildContext context) {
    if (widget.views.isNotEmpty) {
      return const SizedBox.shrink();
    }
    return ViewItem(
      spaceType: widget.spaceType,
      view: ViewPB(
        parentViewId: context
                .read<UserWorkspaceBloc>()
                .state
                .currentWorkspace
                ?.workspaceId ??
            '',
      ),
      level: 0,
      leftPadding: HomeSpaceViewSizes.leftPadding,
      isFeedback: false,
      onSelected: (_, __) {},
      onTertiarySelected: (_, __) {},
      isHoverEnabled: widget.isHoverEnabled,
      isPlaceholder: true,
    );
  }
}
