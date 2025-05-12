import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/trash/application/trash_service.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomPromptDatabaseSelector extends StatefulWidget {
  const CustomPromptDatabaseSelector({
    super.key,
    this.databaseViewId,
    this.isLoading = false,
    this.popoverDirection = PopoverDirection.bottomWithCenterAligned,
    required this.childBuilder,
  });

  final String? databaseViewId;
  final bool isLoading;
  final PopoverDirection popoverDirection;
  final Widget Function(VoidCallback) childBuilder;

  @override
  State<CustomPromptDatabaseSelector> createState() =>
      _CustomPromptDatabaseSelectorState();
}

class _CustomPromptDatabaseSelectorState
    extends State<CustomPromptDatabaseSelector> {
  final popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return ViewSelector(
      viewSelectorCubit: BlocProvider(
        create: (context) => ViewSelectorCubit(
          getIgnoreViewType: getIgnoreViewType,
        ),
      ),
      child: BlocSelector<SpaceBloc, SpaceState, (List<ViewPB>, ViewPB?)>(
        selector: (state) => (state.spaces, state.currentSpace),
        builder: (context, state) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            margin: EdgeInsets.zero,
            offset: const Offset(0, 4.0),
            direction: widget.popoverDirection,
            constraints: const BoxConstraints.tightFor(width: 300, height: 400),
            popupBuilder: (_) {
              return BlocProvider.value(
                value: context.read<ViewSelectorCubit>(),
                child: _PopoverContent(
                  onSelectView: (view) {
                    if (view.layout.isDatabaseView) {
                      context
                          .read<AiPromptSelectorCubit>()
                          .updateCustomPromptDatabaseViewId(view.id);
                      popoverController.close();
                    }
                  },
                ),
              );
            },
            child: widget.childBuilder(
              () {
                if (!widget.isLoading) {
                  context
                      .read<ViewSelectorCubit>()
                      .refreshSources(state.$1, state.$2);
                  popoverController.show();
                }
              },
            ),
          );
        },
      ),
    );
  }

  IgnoreViewType getIgnoreViewType(ViewSelectorItem item) {
    final layout = item.view.layout;

    if (layout.isDatabaseView) {
      return IgnoreViewType.none;
    }
    if (layout.isDocumentView) {
      return hasDatabaseDescendent(item)
          ? IgnoreViewType.none
          : IgnoreViewType.hide;
    }
    return IgnoreViewType.hide;
  }

  bool hasDatabaseDescendent(ViewSelectorItem viewSelectorItem) {
    final layout = viewSelectorItem.view.layout;

    if (layout == ViewLayoutPB.Chat) {
      return false;
    }

    if (layout.isDatabaseView) {
      return true;
    }

    // document may have children
    return viewSelectorItem.children.any(
      (child) => hasDatabaseDescendent(child),
    );
  }
}

class AiPromptDatabaseSelectorButton extends StatefulWidget {
  const AiPromptDatabaseSelectorButton({
    super.key,
    required this.selectedViewId,
    required this.isLoading,
    required this.onTap,
  });

  final String? selectedViewId;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<AiPromptDatabaseSelectorButton> createState() =>
      _AiPromptDatabaseSelectorButtonState();
}

class _AiPromptDatabaseSelectorButtonState
    extends State<AiPromptDatabaseSelectorButton> {
  late Future<ViewPB?> viewFuture;

  @override
  void initState() {
    super.initState();
    viewFuture = getView();
  }

  @override
  void didUpdateWidget(covariant AiPromptDatabaseSelectorButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedViewId != widget.selectedViewId) {
      viewFuture = getView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return FutureBuilder<ViewPB?>(
      future: viewFuture,
      builder: (context, snapshot) {
        String name = "";

        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.done) {
          name = snapshot.data!.nameOrDefault;
        }

        return Row(
          spacing: theme.spacing.s,
          children: [
            Expanded(
              child: Text(
                "${LocaleKeys.ai_customPrompt_promptDatabase.tr()}: $name",
                maxLines: 1,
                style: theme.textStyle.body.standard(
                  color: theme.textColorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 150,
              ),
              child: AFOutlinedButton.normal(
                onTap: widget.onTap,
                builder: (context, isHovering, disabled) {
                  return Row(
                    spacing: theme.spacing.s,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isLoading) buildLoadingIndicator(theme),
                      Flexible(
                        child: Text(
                          widget.isLoading
                              ? LocaleKeys.ai_customPrompt_loading.tr()
                              : LocaleKeys.button_change.tr(),
                          maxLines: 1,
                          style: theme.textStyle.body.standard(
                            color: theme.textColorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildLoadingIndicator(AppFlowyThemeData theme) {
    return SizedBox.square(
      dimension: 20,
      child: Padding(
        padding: EdgeInsets.all(2.5),
        child: CircularProgressIndicator(
          color: theme.iconColorScheme.tertiary,
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  Future<ViewPB?> getView() async {
    if (widget.selectedViewId == null) {
      return null;
    }
    final view =
        await ViewBackendService.getView(widget.selectedViewId!).toNullable();

    if (view != null) {
      return view;
    }

    final trashViews = await TrashService().readTrash().toNullable();
    final trashedItem = trashViews?.items
        .firstWhereOrNull((element) => element.id == widget.selectedViewId);

    if (trashedItem == null) {
      return null;
    }

    return ViewPB()
      ..id = trashedItem.id
      ..name = trashedItem.name;
  }
}

class _PopoverContent extends StatefulWidget {
  const _PopoverContent({
    required this.onSelectView,
  });

  final void Function(ViewPB view) onSelectView;

  @override
  State<_PopoverContent> createState() => _PopoverContentState();
}

class _PopoverContentState extends State<_PopoverContent> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VSpace(theme.spacing.m),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
          ),
          child: AFTextField(
            focusNode: focusNode,
            size: AFTextFieldSize.m,
            hintText: LocaleKeys.search_label.tr(),
            controller: context.read<ViewSelectorCubit>().filterTextController,
          ),
        ),
        VSpace(theme.spacing.m),
        AFDivider(),
        Expanded(
          child: BlocBuilder<ViewSelectorCubit, ViewSelectorState>(
            builder: (context, state) {
              return ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                children: _buildVisibleSources(context, state).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Iterable<Widget> _buildVisibleSources(
    BuildContext context,
    ViewSelectorState state,
  ) {
    return state.visibleSources.map(
      (e) => ViewSelectorTreeItem(
        key: ValueKey(
          'custom_prompt_database_tree_item_${e.view.id}',
        ),
        viewSelectorItem: e,
        level: 0,
        isDescendentOfSpace: e.view.isSpace,
        isSelectedSection: false,
        showCheckbox: false,
        onSelected: (source) {
          widget.onSelectView(source.view);
        },
        height: 30.0,
      ),
    );
  }
}
