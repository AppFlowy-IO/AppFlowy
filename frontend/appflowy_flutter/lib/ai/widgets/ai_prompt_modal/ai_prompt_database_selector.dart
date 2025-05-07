import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomPromptDatabaseSelector extends StatefulWidget {
  const CustomPromptDatabaseSelector({
    super.key,
    required this.databaseViewId,
    required this.isLoading,
  });

  final String? databaseViewId;
  final bool isLoading;

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
          getIgnoreViewType: (view) {
            if (view.layout.isDatabaseView || view.layout.isDocumentView) {
              return IgnoreViewType.none;
            }
            return IgnoreViewType.hide;
          },
        ),
      ),
      child: BlocSelector<SpaceBloc, SpaceState, (List<ViewPB>, ViewPB?)>(
        selector: (state) => (state.spaces, state.currentSpace),
        builder: (context, state) {
          return AppFlowyPopover(
            controller: popoverController,
            triggerActions: PopoverTriggerFlags.none,
            margin: EdgeInsets.zero,
            offset: const Offset(0, 2),
            direction: PopoverDirection.bottomWithRightAligned,
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
            child: _Button(
              selectedViewId: widget.databaseViewId,
              isLoading: widget.isLoading,
              onTap: () {
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
}

class _Button extends StatefulWidget {
  const _Button({
    required this.selectedViewId,
    required this.isLoading,
    required this.onTap,
  });

  final String? selectedViewId;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  late Future<ViewPB?> future;

  @override
  void initState() {
    super.initState();
    future = widget.selectedViewId == null
        ? Future(() => null)
        : ViewBackendService.getView(widget.selectedViewId!)
            .then((f) => f.toNullable());
  }

  @override
  void didUpdateWidget(covariant _Button oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedViewId != widget.selectedViewId) {
      future = widget.selectedViewId == null
          ? Future(() => null)
          : ViewBackendService.getView(widget.selectedViewId!)
              .then((f) => f.toNullable());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return FutureBuilder<ViewPB?>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        final String name;
        final String? tooltip;
        if (widget.isLoading) {
          tooltip = null;
          name = LocaleKeys.ai_customPrompt_loading.tr();
        } else if (!snapshot.hasData ||
            snapshot.connectionState != ConnectionState.done ||
            data == null) {
          name = LocaleKeys.ai_customPrompt_selectDatabase.tr();
          tooltip = LocaleKeys.ai_customPrompt_selectDatabase.tr();
        } else {
          name = tooltip = data.nameOrDefault;
        }

        return FlowyTooltip(
          message: tooltip,
          preferBelow: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 150,
            ),
            child: AFGhostButton.normal(
              onTap: widget.onTap,
              padding: EdgeInsets.symmetric(
                vertical: theme.spacing.xs,
                horizontal: theme.spacing.m,
              ),
              builder: (context, isHovering, disabled) {
                return Row(
                  spacing: theme.spacing.xs,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLoadingIndicator(theme),
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        style: theme.textStyle.body.standard(
                          color: theme.textColorScheme.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!widget.isLoading)
                      FlowySvg(
                        FlowySvgs.toolbar_arrow_down_m,
                        color: theme.iconColorScheme.secondary,
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(AppFlowyThemeData theme) {
    return widget.isLoading
        ? SizedBox.square(
            dimension: 20,
            child: Padding(
              padding: EdgeInsets.all(2.5),
              child: CircularProgressIndicator(
                color: theme.iconColorScheme.tertiary,
                strokeWidth: 2.0,
              ),
            ),
          )
        : const SizedBox.shrink();
  }
}

class _PopoverContent extends StatelessWidget {
  const _PopoverContent({required this.onSelectView});

  final void Function(ViewPB view) onSelectView;

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
            horizontal: theme.spacing.l,
          ),
          child: Text(
            LocaleKeys.ai_customPrompt_loadDatabasePromptsFrom.tr(),
            style: theme.textStyle.caption
                .standard(color: theme.textColorScheme.secondary),
          ),
        ),
        VSpace(theme.spacing.m),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.m,
          ),
          child: AFTextField(
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
          onSelectView(source.view);
        },
        height: 30.0,
      ),
    );
  }
}
