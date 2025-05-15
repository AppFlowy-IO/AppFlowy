import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiPromptCategoryList extends StatefulWidget {
  const AiPromptCategoryList({
    super.key,
  });

  @override
  State<AiPromptCategoryList> createState() => _AiPromptCategoryListState();
}

class _AiPromptCategoryListState extends State<AiPromptCategoryList> {
  bool isSearching = false;
  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return TextFieldTapRegion(
      groupId: "ai_prompt_category_list",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: theme.spacing.l,
            ),
            child: AiPromptFeaturedSection(),
          ),
          Padding(
            padding: EdgeInsets.only(
              right: theme.spacing.l,
            ),
            child: AiPromptCustomPromptSection(),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: theme.spacing.s,
              right: theme.spacing.l,
            ),
            child: AFDivider(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                top: theme.spacing.s,
                right: theme.spacing.l,
              ),
              children: [
                _buildCategoryItem(context, null),
                ...sortedCategories.map(
                  (category) => _buildCategoryItem(
                    context,
                    category,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Iterable<AiPromptCategory> get sortedCategories {
    final categories = [...AiPromptCategory.values];
    categories.sort((a, b) => a.i18n.compareTo(b.i18n));

    return categories;
  }

  Widget _buildCategoryItem(
    BuildContext context,
    AiPromptCategory? category,
  ) {
    return AiPromptCategoryItem(
      category: category,
      onSelect: () {
        context.read<AiPromptSelectorCubit>().selectCategory(category);
      },
    );
  }
}

class AiPromptFeaturedSection extends StatelessWidget {
  const AiPromptFeaturedSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final isSelected = context.watch<AiPromptSelectorCubit>().state.maybeMap(
          ready: (state) => state.isFeaturedSectionSelected,
          orElse: () => false,
        );

    return AFBaseButton(
      onTap: () {
        if (!isSelected) {
          context.read<AiPromptSelectorCubit>().selectFeaturedSection();
        }
      },
      builder: (context, isHovering, disabled) {
        return Text(
          LocaleKeys.ai_customPrompt_featured.tr(),
          style: AppFlowyTheme.of(context).textStyle.body.standard(
                color: theme.textColorScheme.primary,
              ),
          overflow: TextOverflow.ellipsis,
        );
      },
      borderRadius: theme.borderRadius.m,
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      borderColor: (context, isHovering, disabled, isFocused) =>
          Colors.transparent,
      backgroundColor: (context, isHovering, disabled) {
        if (isSelected) {
          return theme.fillColorScheme.themeSelect;
        }
        if (isHovering) {
          return theme.fillColorScheme.contentHover;
        }
        return Colors.transparent;
      },
    );
  }
}

class AiPromptCustomPromptSection extends StatelessWidget {
  const AiPromptCustomPromptSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
      builder: (context, state) {
        return state.maybeMap(
          ready: (readyState) {
            final isSelected = readyState.isCustomPromptSectionSelected;

            return AFBaseButton(
              onTap: () {
                if (!isSelected) {
                  context.read<AiPromptSelectorCubit>().selectCustomSection();
                }
              },
              builder: (context, isHovering, disabled) {
                return Text(
                  LocaleKeys.ai_customPrompt_custom.tr(),
                  style: AppFlowyTheme.of(context).textStyle.body.standard(
                        color: theme.textColorScheme.primary,
                      ),
                  overflow: TextOverflow.ellipsis,
                );
              },
              borderRadius: theme.borderRadius.m,
              padding: EdgeInsets.symmetric(
                vertical: theme.spacing.s,
                horizontal: theme.spacing.m,
              ),
              borderColor: (context, isHovering, disabled, isFocused) =>
                  Colors.transparent,
              backgroundColor: (context, isHovering, disabled) {
                if (isSelected) {
                  return theme.fillColorScheme.themeSelect;
                }
                if (isHovering) {
                  return theme.fillColorScheme.contentHover;
                }
                return Colors.transparent;
              },
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class AiPromptCategoryItem extends StatelessWidget {
  const AiPromptCategoryItem({
    super.key,
    required this.category,
    required this.onSelect,
  });

  final AiPromptCategory? category;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiPromptSelectorCubit, AiPromptSelectorState>(
      builder: (context, state) {
        final theme = AppFlowyTheme.of(context);
        final isSelected = state.maybeMap(
          ready: (state) {
            return !state.isFeaturedSectionSelected &&
                !state.isCustomPromptSectionSelected &&
                state.selectedCategory == category;
          },
          orElse: () => false,
        );

        return AFBaseButton(
          onTap: onSelect,
          builder: (context, isHovering, disabled) {
            return Text(
              category?.i18n ?? LocaleKeys.ai_customPrompt_all.tr(),
              style: AppFlowyTheme.of(context).textStyle.body.standard(
                    color: theme.textColorScheme.primary,
                  ),
              overflow: TextOverflow.ellipsis,
            );
          },
          borderRadius: theme.borderRadius.m,
          padding: EdgeInsets.symmetric(
            vertical: theme.spacing.s,
            horizontal: theme.spacing.m,
          ),
          borderColor: (context, isHovering, disabled, isFocused) =>
              Colors.transparent,
          backgroundColor: (context, isHovering, disabled) {
            if (isSelected) {
              return theme.fillColorScheme.themeSelect;
            }
            if (isHovering) {
              return theme.fillColorScheme.contentHover;
            }
            return Colors.transparent;
          },
        );
      },
    );
  }
}
