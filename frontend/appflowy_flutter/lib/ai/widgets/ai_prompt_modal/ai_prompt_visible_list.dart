import 'package:appflowy/ai/ai.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Duration _listItemAnimationDuration = Duration(milliseconds: 150);

class AiPromptVisibleList extends StatefulWidget {
  const AiPromptVisibleList({
    super.key,
    required this.padding,
  });

  final EdgeInsetsGeometry padding;

  @override
  State<AiPromptVisibleList> createState() => _AiPromptVisibleListState();
}

class _AiPromptVisibleListState extends State<AiPromptVisibleList> {
  final listKey = GlobalKey<AnimatedListState>();
  final scrollController = ScrollController();
  final List<AiPrompt> oldList = [];

  @override
  void initState() {
    super.initState();
    final prompts = context.read<AiPromptSelectorCubit>().state.maybeMap(
          ready: (value) => value.visiblePrompts,
          orElse: () => <AiPrompt>[],
        );
    oldList.addAll(prompts);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppFlowyTheme.of(context).spacing;
    return BlocListener<AiPromptSelectorCubit, AiPromptSelectorState>(
      listener: (context, state) {
        final list = state.maybeMap(
          ready: (state) => state.visiblePrompts,
          orElse: () => <AiPrompt>[],
        );
        handleVisiblePromptListChanged(list);
      },
      child: AnimatedList(
        controller: scrollController,
        padding: widget.padding,
        key: listKey,
        initialItemCount: oldList.length,
        itemBuilder: (context, index, animation) {
          final cubit = context.read<AiPromptSelectorCubit>();

          return cubit.state.maybeMap(
            ready: (state) {
              final prompt = state.visiblePrompts[index];
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : spacing.s,
                  bottom:
                      index == state.visiblePrompts.length - 1 ? 0 : spacing.s,
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

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final cubit = context.read<AiPromptSelectorCubit>();

    final curvedAnimation = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeIn,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: SizeTransition(
        sizeFactor: curvedAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: GestureDetector(
            onTap: () {
              cubit.selectPrompt(widget.prompt.id);
            },
            onDoubleTap: () {
              Navigator.of(context).pop(widget.prompt);
            },
            child: Container(
              padding: EdgeInsets.all(theme.spacing.m),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.borderRadius.m),
                border: Border.all(
                  color: widget.isSelected
                      ? isHovering
                          ? theme.borderColorScheme.themeThickHover
                          : theme.borderColorScheme.themeThick
                      : isHovering
                          ? theme.borderColorScheme.greyTertiaryHover
                          : theme.borderColorScheme.greyTertiary,
                ),
                color: theme.surfaceColorScheme.primary,
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
          ),
        ),
      ),
    );
  }
}
