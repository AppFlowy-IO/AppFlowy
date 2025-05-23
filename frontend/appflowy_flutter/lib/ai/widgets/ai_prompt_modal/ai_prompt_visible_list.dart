import 'dart:async';

import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_prompt_database_modal.dart';

const Duration _listItemAnimationDuration = Duration(milliseconds: 150);

class AiPromptVisibleList extends StatefulWidget {
  const AiPromptVisibleList({
    super.key,
  });

  @override
  State<AiPromptVisibleList> createState() => _AiPromptVisibleListState();
}

class _AiPromptVisibleListState extends State<AiPromptVisibleList> {
  final listKey = GlobalKey<AnimatedListState>();
  final scrollController = ScrollController();
  final List<AiPrompt> oldList = [];

  late AiPromptSelectorCubit cubit;
  late bool filterIsEmpty;

  @override
  void initState() {
    super.initState();
    cubit = context.read<AiPromptSelectorCubit>();
    final textController = cubit.filterTextController;
    filterIsEmpty = textController.text.isEmpty;
    textController.addListener(handleFilterTextChanged);
    final prompts = cubit.state.maybeMap(
      ready: (value) => value.visiblePrompts,
      orElse: () => <AiPrompt>[],
    );
    oldList.addAll(prompts);
  }

  @override
  void dispose() {
    cubit.filterTextController.removeListener(handleFilterTextChanged);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: theme.spacing.l),
          child: buildSearchField(context),
        ),
        VSpace(
          theme.spacing.s,
        ),
        BlocConsumer<AiPromptSelectorCubit, AiPromptSelectorState>(
          listener: (context, state) {
            state.maybeMap(
              ready: (state) {
                handleVisiblePromptListChanged(state.visiblePrompts);
              },
              orElse: () {},
            );
          },
          buildWhen: (p, c) {
            return p.maybeMap(
              ready: (pr) => c.maybeMap(
                ready: (cr) =>
                    pr.databaseConfig?.view.id != cr.databaseConfig?.view.id ||
                    pr.isLoadingCustomPrompts != cr.isLoadingCustomPrompts ||
                    pr.isCustomPromptSectionSelected !=
                        cr.isCustomPromptSectionSelected,
                orElse: () => false,
              ),
              orElse: () => true,
            );
          },
          builder: (context, state) {
            return state.maybeMap(
              ready: (readyState) {
                if (!readyState.isCustomPromptSectionSelected) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: EdgeInsets.only(
                    left: theme.spacing.l,
                    top: theme.spacing.s,
                    right: theme.spacing.l,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${LocaleKeys.ai_customPrompt_promptDatabase.tr()}: ${readyState.databaseConfig?.view.nameOrDefault ?? ""}",
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
                          builder: (context, isHovering, disabled) {
                            return Row(
                              spacing: theme.spacing.s,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (readyState.isLoadingCustomPrompts)
                                  buildLoadingIndicator(theme),
                                Flexible(
                                  child: Text(
                                    readyState.isLoadingCustomPrompts
                                        ? LocaleKeys.ai_customPrompt_loading
                                            .tr()
                                        : LocaleKeys.button_change.tr(),
                                    maxLines: 1,
                                    style: theme.textStyle.body.enhanced(
                                      color: theme.textColorScheme.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                          onTap: () async {
                            final newConfig =
                                await changeCustomPromptDatabaseConfig(
                              context,
                              config: readyState.databaseConfig,
                            );
                            if (newConfig != null && context.mounted) {
                              context
                                  .read<AiPromptSelectorCubit>()
                                  .updateCustomPromptDatabaseConfiguration(
                                    newConfig,
                                  );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
        ),
        Expanded(
          child: TextFieldTapRegion(
            groupId: "ai_prompt_category_list",
            child: BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
              builder: (context, state) {
                return state.maybeMap(
                  ready: (readyState) {
                    if (readyState.visiblePrompts.isEmpty) {
                      return buildEmptyPrompts();
                    }
                    return buildPromptList();
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSearchField(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final iconSize = 20.0;

    return AFTextField(
      groupId: "ai_prompt_category_list",
      hintText: "Search",
      controller: context.read<AiPromptSelectorCubit>().filterTextController,
      autoFocus: true,
      suffixIconConstraints: BoxConstraints.tightFor(
        width: iconSize + theme.spacing.m,
        height: iconSize,
      ),
      suffixIconBuilder: filterIsEmpty
          ? null
          : (context, isObscured) => TextFieldTapRegion(
                groupId: "ai_prompt_category_list",
                child: Padding(
                  padding: EdgeInsets.only(right: theme.spacing.m),
                  child: GestureDetector(
                    onTap: () => context
                        .read<AiPromptSelectorCubit>()
                        .filterTextController
                        .clear(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: FlowySvg(
                        FlowySvgs.search_clear_m,
                        color: theme.iconColorScheme.tertiary,
                        size: const Size.square(20),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget buildEmptyPrompts() {
    final theme = AppFlowyTheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowySvg(
            FlowySvgs.m_home_search_icon_m,
            color: theme.iconColorScheme.secondary,
            size: Size.square(24),
          ),
          VSpace(theme.spacing.m),
          Text(
            LocaleKeys.ai_customPrompt_noResults.tr(),
            style: theme.textStyle.body
                .standard(color: theme.textColorScheme.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget buildPromptList() {
    final theme = AppFlowyTheme.of(context);

    return AnimatedList(
      controller: scrollController,
      padding: EdgeInsets.all(theme.spacing.l),
      key: listKey,
      initialItemCount: oldList.length,
      itemBuilder: (context, index, animation) {
        return BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
          builder: (context, state) {
            return state.maybeMap(
              ready: (state) {
                final prompt = state.visiblePrompts[index];

                return Padding(
                  padding: EdgeInsets.only(
                    top: index == 0 ? 0 : theme.spacing.s,
                    bottom: index == state.visiblePrompts.length - 1
                        ? 0
                        : theme.spacing.s,
                  ),
                  child: _AiPromptListItem(
                    animation: animation,
                    prompt: prompt,
                    isSelected: state.selectedPromptId == prompt.id,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            );
          },
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

  void handleVisiblePromptListChanged(
    List<AiPrompt> newList,
  ) {
    final updates = calculateListDiff(oldList, newList).getUpdatesWithData();

    for (final update in updates) {
      update.when(
        insert: (pos, data) {
          listKey.currentState?.insertItem(
            pos,
            duration: _listItemAnimationDuration,
          );
        },
        remove: (pos, data) {
          listKey.currentState?.removeItem(
            pos,
            (context, animation) {
              final isSelected =
                  context.read<AiPromptSelectorCubit>().state.maybeMap(
                        ready: (state) => state.selectedPromptId == data.id,
                        orElse: () => false,
                      );
              return _AiPromptListItem(
                animation: animation,
                prompt: data,
                isSelected: isSelected,
              );
            },
            duration: _listItemAnimationDuration,
          );
        },
        change: (pos, oldData, newData) {},
        move: (from, to, data) {},
      );
    }
    oldList
      ..clear()
      ..addAll(newList);
  }

  void handleFilterTextChanged() {
    setState(() {
      filterIsEmpty = cubit.filterTextController.text.isEmpty;
    });
  }
}

class _AiPromptListItem extends StatefulWidget {
  const _AiPromptListItem({
    required this.animation,
    required this.prompt,
    required this.isSelected,
  });

  final Animation<double> animation;
  final AiPrompt prompt;
  final bool isSelected;

  @override
  State<_AiPromptListItem> createState() => _AiPromptListItemState();
}

class _AiPromptListItemState extends State<_AiPromptListItem> {
  bool isHovering = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final cubit = context.read<AiPromptSelectorCubit>();

    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeIn,
    );

    final surfacePrimaryHover =
        Theme.of(context).isLightMode ? Color(0xFFF8FAFF) : Color(0xFF3C3F4E);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SizeTransition(
        sizeFactor: curvedAnimation,
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              isHovering = true;
              timer = Timer(const Duration(milliseconds: 300), () {
                if (mounted) {
                  cubit.selectPrompt(widget.prompt.id);
                }
              });
            });
          },
          onExit: (_) {
            setState(() {
              isHovering = false;
              timer?.cancel();
            });
          },
          child: GestureDetector(
            onTap: () {
              cubit.selectPrompt(widget.prompt.id);
            },
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(theme.spacing.m),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(theme.borderRadius.m),
                    color: Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected
                          ? isHovering
                              ? theme.borderColorScheme.themeThickHover
                              : theme.borderColorScheme.themeThick
                          : isHovering
                              ? theme.borderColorScheme.primaryHover
                              : theme.borderColorScheme.primary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.prompt.name,
                              maxLines: 1,
                              style: theme.textStyle.body.standard(
                                color: theme.textColorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.prompt.content,
                        maxLines: 2,
                        style: theme.textStyle.caption.standard(
                          color: theme.textColorScheme.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                if (isHovering)
                  Positioned(
                    top: theme.spacing.s,
                    right: theme.spacing.s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(boxShadow: theme.shadow.small),
                      child: AFBaseButton(
                        onTap: () {
                          Navigator.of(context).pop(widget.prompt);
                        },
                        builder: (context, isHovering, disabled) {
                          return Text(
                            LocaleKeys.ai_customPrompt_usePrompt.tr(),
                            style: theme.textStyle.body.standard(
                              color: theme.textColorScheme.primary,
                            ),
                          );
                        },
                        backgroundColor: (context, isHovering, disabled) {
                          if (isHovering) {
                            return surfacePrimaryHover;
                          }
                          return theme.surfaceColorScheme.primary;
                        },
                        padding: EdgeInsets.symmetric(
                          vertical: theme.spacing.s,
                          horizontal: theme.spacing.m,
                        ),
                        borderRadius: theme.borderRadius.m,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
