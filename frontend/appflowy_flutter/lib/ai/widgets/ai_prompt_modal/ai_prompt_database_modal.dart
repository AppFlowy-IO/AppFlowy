import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/ai/service/ai_prompt_database_selector_cubit.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/dialog_v2.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<CustomPromptDatabaseConfig?> changeCustomPromptDatabaseConfig(
  BuildContext context, {
  CustomPromptDatabaseConfig? config,
}) async {
  return showDialog<CustomPromptDatabaseConfig?>(
    context: context,
    builder: (_) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: context.read<UserWorkspaceBloc>(),
          ),
          BlocProvider(
            create: (context) => AiPromptDatabaseSelectorCubit(
              configuration: config,
            ),
          ),
        ],
        child: const AiPromptDatabaseModal(),
      );
    },
  );
}

class AiPromptDatabaseModal extends StatefulWidget {
  const AiPromptDatabaseModal({
    super.key,
  });

  @override
  State<AiPromptDatabaseModal> createState() => _AiPromptDatabaseModalState();
}

class _AiPromptDatabaseModalState extends State<AiPromptDatabaseModal> {
  final expandableController = ExpandableController(initialExpanded: false);

  @override
  void dispose() {
    expandableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocListener<AiPromptDatabaseSelectorCubit,
        AiPromptDatabaseSelectorState>(
      listener: (context, state) {
        state.maybeMap(
          invalidDatabase: (_) {
            showSimpleAFDialog(
              context: context,
              title: LocaleKeys.ai_customPrompt_invalidDatabase.tr(),
              content: LocaleKeys.ai_customPrompt_invalidDatabaseHelp.tr(),
              primaryAction: (
                LocaleKeys.button_ok.tr(),
                (context) {},
              ),
            );
          },
          empty: (_) => expandableController.expanded = false,
          selected: (_) => expandableController.expanded = true,
          orElse: () {},
        );
      },
      child: AFModal(
        constraints: const BoxConstraints(
          maxWidth: 450,
          maxHeight: 400,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AFModalHeader(
              leading: Text(
                LocaleKeys.ai_customPrompt_configureDatabase.tr(),
                style: theme.textStyle.heading4.prominent(
                  color: theme.textColorScheme.primary,
                ),
              ),
              trailing: [
                AFGhostButton.normal(
                  onTap: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.all(theme.spacing.xs),
                  builder: (context, isHovering, disabled) {
                    return Center(
                      child: FlowySvg(
                        FlowySvgs.toast_close_s,
                        size: Size.square(20),
                      ),
                    );
                  },
                ),
              ],
            ),
            Flexible(
              child: AFModalBody(
                child: ExpandablePanel(
                  controller: expandableController,
                  theme: ExpandableThemeData(
                    tapBodyToCollapse: false,
                    hasIcon: false,
                    tapBodyToExpand: false,
                    tapHeaderToExpand: false,
                  ),
                  header: const _Header(),
                  collapsed: const SizedBox.shrink(),
                  expanded: const _Expanded(),
                ),
              ),
            ),
            AFModalFooter(
              trailing: [
                AFOutlinedButton.normal(
                  onTap: () => Navigator.of(context).pop(),
                  builder: (context, isHovering, disabled) {
                    return Text(
                      LocaleKeys.button_cancel.tr(),
                      style: theme.textStyle.body.standard(
                        color: theme.textColorScheme.primary,
                      ),
                    );
                  },
                ),
                AFFilledButton.primary(
                  onTap: () {
                    final config = context
                        .read<AiPromptDatabaseSelectorCubit>()
                        .state
                        .maybeMap(
                          selected: (state) => state.config,
                          orElse: () => null,
                        );
                    Navigator.of(context).pop(config);
                  },
                  builder: (context, isHovering, disabled) {
                    return Text(
                      LocaleKeys.button_done.tr(),
                      style: theme.textStyle.body.enhanced(
                        color: theme.textColorScheme.onFill,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header();

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final popoverController = AFPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<AiPromptDatabaseSelectorCubit,
        AiPromptDatabaseSelectorState>(
      builder: (context, state) {
        bool showNothing = false;
        String? viewName;
        state.maybeMap(
          empty: (_) {
            showNothing = false;
            viewName = null;
          },
          selected: (selectedState) {
            showNothing = false;
            viewName = selectedState.config.view.nameOrDefault;
          },
          orElse: () {
            showNothing = true;
            viewName = null;
          },
        );

        if (showNothing) {
          return SizedBox.shrink();
        }

        return Center(
          child: ViewSelector(
            viewSelectorCubit: BlocProvider(
              create: (context) => ViewSelectorCubit(
                getIgnoreViewType: getIgnoreViewType,
              ),
            ),
            child: BlocSelector<SpaceBloc, SpaceState, (List<ViewPB>, ViewPB?)>(
              selector: (state) => (state.spaces, state.currentSpace),
              builder: (context, state) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: theme.spacing.xl,
                  ),
                  child: AFPopover(
                    controller: popoverController,
                    decoration: BoxDecoration(
                      color: theme.surfaceColorScheme.primary,
                      borderRadius: BorderRadius.circular(theme.borderRadius.l),
                      border: Border.all(
                        color: theme.borderColorScheme.primary,
                      ),
                      boxShadow: theme.shadow.medium,
                    ),
                    anchor: AFAnchor(
                      childAlignment: Alignment.topCenter,
                      overlayAlignment: Alignment.bottomCenter,
                      offset: Offset(0, theme.spacing.xs),
                    ),
                    popover: (context) {
                      return _PopoverContent(
                        onSelectViewItem: (item) {
                          context
                              .read<AiPromptDatabaseSelectorCubit>()
                              .selectDatabaseView(item.view.id);
                          popoverController.hide();
                        },
                      );
                    },
                    child: AFOutlinedButton.normal(
                      onTap: () {
                        context
                            .read<ViewSelectorCubit>()
                            .refreshSources(state.$1, state.$2);
                        popoverController.toggle();
                      },
                      builder: (context, isHovering, disabled) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: theme.spacing.s,
                          children: [
                            Flexible(
                              child: Text(
                                viewName == null
                                    ? LocaleKeys.ai_customPrompt_selectDatabase
                                        .tr()
                                    : viewName!,
                                style: theme.textStyle.body.enhanced(
                                  color: theme.textColorScheme.primary,
                                ),
                              ),
                            ),
                            FlowySvg(
                              FlowySvgs.toolbar_arrow_down_m,
                              size: Size(12, 20),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
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

class _Expanded extends StatelessWidget {
  const _Expanded();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<AiPromptDatabaseSelectorCubit,
        AiPromptDatabaseSelectorState>(
      builder: (context, state) {
        return state.maybeMap(
          orElse: () => SizedBox.shrink(),
          selected: (selectedState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.borderRadius.l),
              ),
              padding: EdgeInsets.all(
                theme.spacing.m,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.spacing.m,
                children: [
                  FieldSelector(
                    title: LocaleKeys.ai_customPrompt_title.tr(),
                    currentFieldId: selectedState.config.titleFieldId,
                    isDisabled: true,
                    onSelect: (id) {},
                  ),
                  FieldSelector(
                    title: LocaleKeys.ai_customPrompt_content.tr(),
                    currentFieldId: selectedState.config.contentFieldId,
                    onSelect: (id) {
                      if (id != null) {
                        context
                            .read<AiPromptDatabaseSelectorCubit>()
                            .selectContentField(id);
                      }
                    },
                  ),
                  FieldSelector(
                    title: LocaleKeys.ai_customPrompt_example.tr(),
                    currentFieldId: selectedState.config.exampleFieldId,
                    isOptional: true,
                    onSelect: (id) {
                      context
                          .read<AiPromptDatabaseSelectorCubit>()
                          .selectExampleField(id);
                    },
                  ),
                  FieldSelector(
                    title: LocaleKeys.ai_customPrompt_category.tr(),
                    currentFieldId: selectedState.config.categoryFieldId,
                    isOptional: true,
                    onSelect: (id) {
                      context
                          .read<AiPromptDatabaseSelectorCubit>()
                          .selectCategoryField(id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PopoverContent extends StatefulWidget {
  const _PopoverContent({
    required this.onSelectViewItem,
  });

  final void Function(ViewSelectorItem item) onSelectViewItem;

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

    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(
        width: 300,
        height: 400,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VSpace(
            theme.spacing.m,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.m,
            ),
            child: AFTextField(
              focusNode: focusNode,
              size: AFTextFieldSize.m,
              hintText: LocaleKeys.search_label.tr(),
              controller:
                  context.read<ViewSelectorCubit>().filterTextController,
            ),
          ),
          VSpace(
            theme.spacing.m,
          ),
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
          'custom_prompt_database_tree_item_${e.view.id}',
        ),
        viewSelectorItem: e,
        level: 0,
        isDescendentOfSpace: e.view.isSpace,
        isSelectedSection: false,
        showCheckbox: false,
        onSelected: (item) {
          if (item.view.isDocument || item.view.isSpace) {
            context.read<ViewSelectorCubit>().toggleIsExpanded(item, false);
            return;
          }
          widget.onSelectViewItem(item);
        },
        height: 30.0,
      ),
    );
  }
}

class FieldSelector extends StatefulWidget {
  const FieldSelector({
    super.key,
    required this.title,
    required this.currentFieldId,
    this.isDisabled = false,
    this.isOptional = false,
    required this.onSelect,
  });

  final String title;
  final String? currentFieldId;
  final bool isDisabled;
  final bool isOptional;
  final void Function(String? id)? onSelect;

  @override
  State<FieldSelector> createState() => _FieldSelectorState();
}

class _FieldSelectorState extends State<FieldSelector> {
  final popoverController = AFPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<AiPromptDatabaseSelectorCubit,
        AiPromptDatabaseSelectorState>(
      builder: (context, state) {
        final fields = _getVisibleFields(state);
        final selectedField = fields.firstWhereOrNull(
          (field) => field.id == widget.currentFieldId,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: theme.textStyle.body.standard(
                color: theme.textColorScheme.secondary,
              ),
            ),
            AFPopover(
              controller: popoverController,
              decoration: BoxDecoration(
                color: theme.surfaceColorScheme.primary,
                borderRadius: BorderRadius.circular(theme.borderRadius.l),
                border: Border.all(
                  color: theme.borderColorScheme.primary,
                ),
                boxShadow: theme.shadow.medium,
              ),
              anchor: AFAnchor(
                childAlignment: Alignment.topRight,
                overlayAlignment: Alignment.bottomRight,
                offset: Offset(0, theme.spacing.xs),
              ),
              popover: (context) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: ListView.builder(
                    itemCount: fields.length + (widget.isOptional ? 1 : 0),
                    shrinkWrap: true,
                    padding: EdgeInsets.all(theme.spacing.m),
                    itemBuilder: (context, index) {
                      if (widget.isOptional && index == 0) {
                        return AFMenuItem(
                          title: LocaleKeys.ai_customPrompt_selectField.tr(),
                          onTap: () {
                            widget.onSelect?.call(null);
                            popoverController.hide();
                          },
                          trailing: selectedField == null
                              ? FlowySvg(
                                  FlowySvgs.check_s,
                                  size: const Size.square(20),
                                  color: theme.fillColorScheme.themeThick,
                                )
                              : null,
                        );
                      }
                      final field = fields[index - (widget.isOptional ? 1 : 0)];
                      return AFMenuItem(
                        title: field.name,
                        trailing: field.id == selectedField?.id
                            ? FlowySvg(
                                FlowySvgs.check_s,
                                size: const Size.square(20),
                                color: theme.fillColorScheme.themeThick,
                              )
                            : null,
                        onTap: () {
                          widget.onSelect?.call(field.id);
                          popoverController.hide();
                        },
                      );
                    },
                  ),
                );
              },
              child: AFOutlinedButton.normal(
                disabled: widget.isDisabled,
                builder: (context, isHovering, disabled) {
                  return Row(
                    children: [
                      Text(
                        selectedField?.name ??
                            LocaleKeys.ai_customPrompt_selectField.tr(),
                        style: theme.textStyle.body.enhanced(
                          color: disabled
                              ? theme.textColorScheme.tertiary
                              : selectedField == null
                                  ? theme.textColorScheme.secondary
                                  : theme.textColorScheme.primary,
                        ),
                      ),
                      HSpace(
                        theme.spacing.s,
                      ),
                      FlowySvg(
                        FlowySvgs.toolbar_arrow_down_m,
                        size: Size(12, 20),
                      ),
                    ],
                  );
                },
                onTap: () => popoverController.toggle(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<FieldPB> _getVisibleFields(AiPromptDatabaseSelectorState state) {
    return state.maybeMap(
      orElse: () => [],
      selected: (value) {
        return value.fields
            .where((field) => field.fieldType == FieldType.RichText)
            .toList();
      },
    );
  }
}
