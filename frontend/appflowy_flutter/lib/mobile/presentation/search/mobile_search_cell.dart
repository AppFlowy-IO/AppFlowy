import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mobile_view_ancestors.dart';

class MobileSearchResultCell extends StatelessWidget {
  const MobileSearchResultCell({
    super.key,
    required this.item,
    this.query,
    this.view,
  });
  final SearchResultItem item;
  final ViewPB? view;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final commandPaletteState = context.read<CommandPaletteBloc>().state;
    final displayName = item.displayName.isEmpty
        ? LocaleKeys.menuAppHeader_defaultNewPageName.tr()
        : item.displayName;
    final titleStyle = theme.textStyle.heading4
        .standard(color: theme.textColorScheme.primary)
        .copyWith(height: 24 / 16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 24,
            child: Center(
              child: (view?.toSearchResultItem().icon ?? item.icon)
                  .buildIcon(context),
            ),
          ),
          HSpace(12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: buildHighLightSpan(
                    content: displayName,
                    normal: titleStyle,
                    highlight: titleStyle.copyWith(
                      backgroundColor: theme.fillColorScheme.themeSelect,
                    ),
                  ),
                ),
                buildPath(commandPaletteState, theme),
                ...buildSummary(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPath(CommandPaletteState state, AppFlowyThemeData theme) {
    return BlocProvider(
      create: (context) => ViewAncestorBloc(item.id),
      child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
        builder: (context, state) {
          final ancestors = state.ancestor.ancestors;
          if(ancestors.isEmpty) return const SizedBox.shrink();
          List<String> displayPath = ancestors.map((e) => e.name).toList();
          if (ancestors.length > 2) {
            displayPath = [ancestors.first.name, '...', ancestors.last.name];
          }
          return Text(
            displayPath.join(' / '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.body
                .standard(color: theme.textColorScheme.tertiary),
          );
        },
      ),
    );
  }

  List<Widget> buildSummary(AppFlowyThemeData theme) {
    if (item.content.isEmpty) return [];
    return [
      VSpace(theme.spacing.m),
      RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: buildHighLightSpan(
          content: item.content,
          normal: theme.textStyle.body
              .standard(color: theme.textColorScheme.secondary),
          highlight: theme.textStyle.body
              .standard(color: theme.textColorScheme.primary)
              .copyWith(
                backgroundColor: theme.fillColorScheme.themeSelect,
              ),
        ),
      ),
    ];
  }

  TextSpan buildHighLightSpan({
    required String content,
    required TextStyle normal,
    required TextStyle highlight,
  }) {
    final queryText = (query ?? '').trim();
    if (queryText.isEmpty) {
      return TextSpan(text: content, style: normal);
    }
    final contents = content.splitIncludeSeparator(queryText);
    return TextSpan(
      children: List.generate(contents.length, (index) {
        final content = contents[index];
        final isHighlight = content.toLowerCase() == queryText.toLowerCase();
        return TextSpan(
          text: content,
          style: isHighlight ? highlight : normal,
        );
      }),
    );
  }
}

extension ViewPBToSearchResultItem on ViewPB {
  SearchResultItem toSearchResultItem() {
    final hasIcon = icon.value.isNotEmpty;
    return SearchResultItem(
      id: id,
      displayName: nameOrDefault,
      icon: ResultIconPB(
        ty: hasIcon
            ? ResultIconTypePB.valueOf(icon.ty.value)
            : ResultIconTypePB.Icon,
        value: hasIcon ? icon.value : '${layout.value}',
      ),
      content: '',
    );
  }
}

extension StringSplitExtension on String {
  List<String> splitIncludeSeparator(String separator) {
    final splits =
        split(RegExp(RegExp.escape(separator), caseSensitive: false));
    final List<String> contents = [];
    int charIndex = 0;
    final seperatorLength = separator.length;
    for (int i = 0; i < splits.length; i++) {
      contents.add(splits[i]);
      charIndex += splits[i].length;
      if (i != splits.length - 1) {
        contents.add(substring(charIndex, charIndex + seperatorLength));
        charIndex += seperatorLength;
      }
    }
    return contents;
  }
}
