import 'dart:math';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../service/view_selector_cubit.dart';
import '../view_selector.dart';
import 'layout_define.dart';
import 'mention_page_menu.dart';

class PromptInputDesktopSelectSourcesButton extends StatefulWidget {
  const PromptInputDesktopSelectSourcesButton({
    super.key,
    required this.selectedSourcesNotifier,
    required this.onUpdateSelectedSources,
  });

  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final void Function(List<String>) onUpdateSelectedSources;

  @override
  State<PromptInputDesktopSelectSourcesButton> createState() =>
      _PromptInputDesktopSelectSourcesButtonState();
}

class _PromptInputDesktopSelectSourcesButtonState
    extends State<PromptInputDesktopSelectSourcesButton> {
  late final cubit = ViewSelectorCubit(
    maxSelectedParentPageCount: 3,
    getIgnoreViewType: (item) {
      final view = item.view;

      if (view.isSpace) {
        return IgnoreViewType.none;
      }
      if (view.layout == ViewLayoutPB.Chat) {
        return IgnoreViewType.hide;
      }
      if (view.layout != ViewLayoutPB.Document) {
        return IgnoreViewType.disable;
      }

      return IgnoreViewType.none;
    },
  );
  final popoverController = PopoverController();

  @override
  void initState() {
    super.initState();
    widget.selectedSourcesNotifier.addListener(onSelectedSourcesChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onSelectedSourcesChanged();
    });
  }

  @override
  void dispose() {
    widget.selectedSourcesNotifier.removeListener(onSelectedSourcesChanged);
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewSelector(
      viewSelectorCubit: BlocProvider.value(
        value: cubit,
      ),
      child: BlocBuilder<SpaceBloc, SpaceState>(
        builder: (context, state) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(320, 380)),
            offset: const Offset(0.0, -10.0),
            direction: PopoverDirection.topWithCenterAligned,
            margin: EdgeInsets.zero,
            controller: popoverController,
            onOpen: () {
              context
                  .read<ViewSelectorCubit>()
                  .refreshSources(state.spaces, state.currentSpace);
            },
            onClose: () {
              widget.onUpdateSelectedSources(cubit.selectedSourceIds);
              context
                  .read<ViewSelectorCubit>()
                  .refreshSources(state.spaces, state.currentSpace);
            },
            popupBuilder: (_) {
              return BlocProvider.value(
                value: context.read<ViewSelectorCubit>(),
                child: const _PopoverContent(),
              );
            },
            child: _IndicatorButton(
              selectedSourcesNotifier: widget.selectedSourcesNotifier,
              onTap: () => popoverController.show(),
            ),
          );
        },
      ),
    );
  }

  void onSelectedSourcesChanged() {
    cubit
      ..updateSelectedSources(widget.selectedSourcesNotifier.value)
      ..updateSelectedStatus();
  }
}

class _IndicatorButton extends StatelessWidget {
  const _IndicatorButton({
    required this.selectedSourcesNotifier,
    required this.onTap,
  });

  final ValueNotifier<List<String>> selectedSourcesNotifier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: DesktopAIPromptSizes.actionBarButtonSize,
        child: FlowyHover(
          style: const HoverStyle(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 4, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowySvg(
                  FlowySvgs.ai_page_s,
                  color: Theme.of(context).hintColor,
                ),
                const HSpace(2.0),
                ValueListenableBuilder(
                  valueListenable: selectedSourcesNotifier,
                  builder: (context, selectedSourceIds, _) {
                    final documentId =
                        context.read<DocumentBloc?>()?.documentId;
                    final label = documentId != null &&
                            selectedSourceIds.length == 1 &&
                            selectedSourceIds[0] == documentId
                        ? LocaleKeys.chat_currentPage.tr()
                        : selectedSourceIds.length.toString();
                    return FlowyText(
                      label,
                      fontSize: 12,
                      figmaLineHeight: 16,
                      color: Theme.of(context).hintColor,
                    );
                  },
                ),
                const HSpace(2.0),
                FlowySvg(
                  FlowySvgs.ai_source_drop_down_s,
                  color: Theme.of(context).hintColor,
                  size: const Size.square(8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopoverContent extends StatelessWidget {
  const _PopoverContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ViewSelectorCubit, ViewSelectorState>(
      builder: (context, state) {
        final theme = AppFlowyTheme.of(context);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: AFTextField(
                size: AFTextFieldSize.m,
                controller:
                    context.read<ViewSelectorCubit>().filterTextController,
                hintText: LocaleKeys.search_label.tr(),
              ),
            ),
            AFDivider(
              startIndent: theme.spacing.l,
              endIndent: theme.spacing.l,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                children: [
                  ..._buildSelectedSources(context, state),
                  if (state.selectedSources.isNotEmpty &&
                      state.visibleSources.isNotEmpty)
                    AFDivider(
                      spacing: 4.0,
                      startIndent: theme.spacing.l,
                      endIndent: theme.spacing.l,
                    ),
                  ..._buildVisibleSources(context, state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<Widget> _buildSelectedSources(
    BuildContext context,
    ViewSelectorState state,
  ) {
    return state.selectedSources.map(
      (e) => ViewSelectorTreeItem(
        key: ValueKey(
          'selected_select_sources_tree_item_${e.view.id}',
        ),
        viewSelectorItem: e,
        level: 0,
        isDescendentOfSpace: e.view.isSpace,
        isSelectedSection: true,
        onSelected: (item) {
          context.read<ViewSelectorCubit>().toggleSelectedStatus(item, true);
        },
        height: 30.0,
      ),
    );
  }

  Iterable<Widget> _buildVisibleSources(
    BuildContext context,
    ViewSelectorState state,
  ) {
    return state.visibleSources.map(
      (e) => ViewSelectorTreeItem(
        key: ValueKey(
          'visible_select_sources_tree_item_${e.view.id}',
        ),
        viewSelectorItem: e,
        level: 0,
        isDescendentOfSpace: e.view.isSpace,
        isSelectedSection: false,
        onSelected: (item) {
          context.read<ViewSelectorCubit>().toggleSelectedStatus(item, false);
        },
        height: 30.0,
      ),
    );
  }
}

class ViewSelectorTreeItem extends StatefulWidget {
  const ViewSelectorTreeItem({
    super.key,
    required this.viewSelectorItem,
    required this.level,
    required this.isDescendentOfSpace,
    required this.isSelectedSection,
    required this.onSelected,
    this.onAdd,
    required this.height,
    this.showSaveButton = false,
    this.showCheckbox = true,
  });

  final ViewSelectorItem viewSelectorItem;

  /// nested level of the view item
  final int level;

  final bool isDescendentOfSpace;

  final bool isSelectedSection;

  final void Function(ViewSelectorItem viewSelectorItem) onSelected;

  final void Function(ViewSelectorItem viewSelectorItem)? onAdd;

  final bool showSaveButton;

  final double height;

  final bool showCheckbox;

  @override
  State<ViewSelectorTreeItem> createState() => _ViewSelectorTreeItemState();
}

class _ViewSelectorTreeItemState extends State<ViewSelectorTreeItem> {
  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: widget.height,
      child: ViewSelectorTreeItemInner(
        viewSelectorItem: widget.viewSelectorItem,
        level: widget.level,
        isDescendentOfSpace: widget.isDescendentOfSpace,
        isSelectedSection: widget.isSelectedSection,
        showCheckbox: widget.showCheckbox,
        showSaveButton: widget.showSaveButton,
        onSelected: widget.onSelected,
        onAdd: widget.onAdd,
      ),
    );

    final disabledEnabledChild = widget.viewSelectorItem.isDisabled
        ? FlowyTooltip(
            message: widget.showCheckbox
                ? switch (widget.viewSelectorItem.view.layout) {
                    ViewLayoutPB.Document =>
                      LocaleKeys.chat_sourcesLimitReached.tr(),
                    _ => LocaleKeys.chat_sourceUnsupported.tr(),
                  }
                : "",
            child: Opacity(
              opacity: 0.5,
              child: MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: IgnorePointer(child: child),
              ),
            ),
          )
        : child;

    return ValueListenableBuilder(
      valueListenable: widget.viewSelectorItem.isExpandedNotifier,
      builder: (context, isExpanded, child) {
        // filter the child views that should be ignored
        final childViews = widget.viewSelectorItem.children;

        if (!isExpanded || childViews.isEmpty) {
          return disabledEnabledChild;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            disabledEnabledChild,
            ...childViews.map(
              (childSource) => ViewSelectorTreeItem(
                key: ValueKey(
                  'select_sources_tree_item_${childSource.view.id}',
                ),
                viewSelectorItem: childSource,
                level: widget.level + 1,
                isDescendentOfSpace: widget.isDescendentOfSpace,
                isSelectedSection: widget.isSelectedSection,
                onSelected: widget.onSelected,
                height: widget.height,
                showCheckbox: widget.showCheckbox,
                showSaveButton: widget.showSaveButton,
                onAdd: widget.onAdd,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ViewSelectorTreeItemInner extends StatelessWidget {
  const ViewSelectorTreeItemInner({
    super.key,
    required this.viewSelectorItem,
    required this.level,
    required this.isDescendentOfSpace,
    required this.isSelectedSection,
    required this.showCheckbox,
    required this.showSaveButton,
    this.onSelected,
    this.onAdd,
  });

  final ViewSelectorItem viewSelectorItem;
  final int level;
  final bool isDescendentOfSpace;
  final bool isSelectedSection;
  final bool showCheckbox;
  final bool showSaveButton;
  final void Function(ViewSelectorItem)? onSelected;
  final void Function(ViewSelectorItem)? onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => onSelected?.call(viewSelectorItem),
      child: FlowyHover(
        style: HoverStyle(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        builder: (context, onHover) {
          final isSaveButtonVisible =
              showSaveButton && !viewSelectorItem.view.isSpace;
          final isAddButtonVisible = onAdd != null;
          return Row(
            children: [
              const HSpace(4.0),
              HSpace(max(20.0 * level - (isDescendentOfSpace ? 2 : 0), 0)),
              // builds the >, ^ or · button
              ToggleIsExpandedButton(
                viewSelectorItem: viewSelectorItem,
                isSelectedSection: isSelectedSection,
              ),
              const HSpace(2.0),
              // checkbox
              if (!viewSelectorItem.view.isSpace && showCheckbox) ...[
                SourceSelectedStatusCheckbox(
                  viewSelectorItem: viewSelectorItem,
                ),
                const HSpace(4.0),
              ],
              // icon
              MentionViewIcon(
                view: viewSelectorItem.view,
              ),
              const HSpace(6.0),
              // title
              Expanded(
                child: FlowyText(
                  viewSelectorItem.view.nameOrDefault,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 14.0,
                  figmaLineHeight: 18.0,
                ),
              ),
              if (onHover && (isSaveButtonVisible || isAddButtonVisible)) ...[
                const HSpace(4.0),
                if (isSaveButtonVisible)
                  FlowyIconButton(
                    tooltipText: LocaleKeys.chat_addToPageButton.tr(),
                    width: 24,
                    icon: FlowySvg(
                      FlowySvgs.ai_add_to_page_s,
                      size: const Size.square(16),
                      color: Theme.of(context).hintColor,
                    ),
                    onPressed: () => onSelected?.call(viewSelectorItem),
                  ),
                if (isSaveButtonVisible && isAddButtonVisible)
                  const HSpace(4.0),
                if (isAddButtonVisible)
                  FlowyIconButton(
                    tooltipText: LocaleKeys.chat_addToNewPage.tr(),
                    width: 24,
                    icon: FlowySvg(
                      FlowySvgs.add_less_padding_s,
                      size: const Size.square(16),
                      color: Theme.of(context).hintColor,
                    ),
                    onPressed: () => onAdd?.call(viewSelectorItem),
                  ),
                const HSpace(4.0),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ToggleIsExpandedButton extends StatelessWidget {
  const ToggleIsExpandedButton({
    super.key,
    required this.viewSelectorItem,
    required this.isSelectedSection,
  });

  final ViewSelectorItem viewSelectorItem;
  final bool isSelectedSection;

  @override
  Widget build(BuildContext context) {
    if (isReferencedDatabaseView(
      viewSelectorItem.view,
      viewSelectorItem.parentView,
    )) {
      return const _DotIconWidget();
    }

    if (viewSelectorItem.children.isEmpty) {
      return const SizedBox.square(dimension: 16.0);
    }

    return FlowyHover(
      child: GestureDetector(
        child: ValueListenableBuilder(
          valueListenable: viewSelectorItem.isExpandedNotifier,
          builder: (context, value, _) => FlowySvg(
            value
                ? FlowySvgs.view_item_expand_s
                : FlowySvgs.view_item_unexpand_s,
            size: const Size.square(16.0),
          ),
        ),
        onTap: () => context
            .read<ViewSelectorCubit>()
            .toggleIsExpanded(viewSelectorItem, isSelectedSection),
      ),
    );
  }
}

class _DotIconWidget extends StatelessWidget {
  const _DotIconWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class SourceSelectedStatusCheckbox extends StatelessWidget {
  const SourceSelectedStatusCheckbox({
    super.key,
    required this.viewSelectorItem,
  });

  final ViewSelectorItem viewSelectorItem;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: viewSelectorItem.selectedStatusNotifier,
      builder: (context, selectedStatus, _) => FlowySvg(
        switch (selectedStatus) {
          ViewSelectedStatus.unselected => FlowySvgs.uncheck_s,
          ViewSelectedStatus.selected => FlowySvgs.check_filled_s,
          ViewSelectedStatus.partiallySelected => FlowySvgs.check_partial_s,
        },
        size: const Size.square(18.0),
        blendMode: null,
      ),
    );
  }
}
