import 'package:appflowy/ai/ai.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiPromptCategoryList extends StatelessWidget {
  const AiPromptCategoryList({
    super.key,
    required this.padding,
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Padding(
      padding: padding,
      child: TextFieldTapRegion(
        groupId: "ai_prompt_category_list",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: theme.spacing.s,
          children: [
            _buildSearchField(context),
            _buildFeaturedCategory(context),
            const AFDivider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCategoryItem(context, null),
                  _buildCategoryItem(context, AiPromptCategory.development),
                  _buildCategoryItem(context, AiPromptCategory.writing),
                  _buildCategoryItem(context, AiPromptCategory.business),
                  _buildCategoryItem(context, AiPromptCategory.marketing),
                  _buildCategoryItem(context, AiPromptCategory.learning),
                  _buildCategoryItem(
                    context,
                    AiPromptCategory.healthAndFitness,
                  ),
                  _buildCategoryItem(context, AiPromptCategory.travel),
                  _buildCategoryItem(context, AiPromptCategory.contentSeo),
                  _buildCategoryItem(context, AiPromptCategory.emailMarketing),
                  _buildCategoryItem(context, AiPromptCategory.paidAds),
                  _buildCategoryItem(context, AiPromptCategory.prCommunication),
                  _buildCategoryItem(context, AiPromptCategory.recruiting),
                  _buildCategoryItem(context, AiPromptCategory.sales),
                  _buildCategoryItem(context, AiPromptCategory.socialMedia),
                  _buildCategoryItem(context, AiPromptCategory.strategy),
                  _buildCategoryItem(context, AiPromptCategory.caseStudies),
                  _buildCategoryItem(context, AiPromptCategory.salesCopy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return AFTextField(
      groupId: "ai_prompt_category_list",
      hintText: "Search",
      size: AFTextFieldSize.m,
      controller: context.read<AiPromptSelectorCubit>().filterTextController,
      autoFocus: true,
    );
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

  Widget _buildFeaturedCategory(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final isSelected = context.watch<AiPromptSelectorCubit>().state.maybeMap(
          ready: (state) => state.isFeaturedCategorySelected,
          orElse: () => false,
        );

    return AFBaseButton(
      onTap: () {
        if (!isSelected) {
          context.read<AiPromptSelectorCubit>().selectFeaturedCategory();
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
          return theme.fillColorScheme.primaryAlpha5;
        }
        return Colors.transparent;
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
    final theme = AppFlowyTheme.of(context);
    final isSelected = context.watch<AiPromptSelectorCubit>().state.maybeMap(
          ready: (state) =>
              !state.isFeaturedCategorySelected &&
              state.selectedCategory == category,
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
          return theme.fillColorScheme.primaryAlpha5;
        }
        return Colors.transparent;
      },
    );
  }
}
