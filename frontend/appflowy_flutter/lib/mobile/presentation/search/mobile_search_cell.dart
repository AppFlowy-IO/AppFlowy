import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mobile_view_ancestors.dart';

class MobileSearchResultCell extends StatelessWidget {
  const MobileSearchResultCell({super.key, required this.item, this.query});
  final SearchResultItem item;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        textColor = theme.textColorScheme.primary;
    final commandPaletteState = context.read<CommandPaletteBloc>().state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIcon(),
          HSpace(12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: buildHighLightSpan(
                    content: item.displayName,
                    normal: theme.textStyle.heading4.standard(color: textColor),
                    highlight: theme.textStyle.heading4
                        .standard(color: textColor)
                        .copyWith(
                          backgroundColor: theme.fillColorScheme.themeSelect,
                        ),
                  ),
                ),
                buildPath(commandPaletteState, theme),
                buildSummary(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIcon() {
    final icon = item.icon;
    if (icon.ty == ResultIconTypePB.Emoji) {
      return icon.getIcon(size: 16.0, lineHeight: 20 / 16) ?? SizedBox.shrink();
    } else {
      return icon.getIcon(size: 20) ?? SizedBox.shrink();
    }
  }

  Widget buildPath(CommandPaletteState state, AppFlowyThemeData theme) {
    bool isInTrash = false;
    for (final view in state.trash) {
      if (view.id == item.id) {
        isInTrash = true;
        break;
      }
    }
    if (isInTrash) {
      return Row(
        children: [
          const FlowySvg(FlowySvgs.trash_s, size: Size.square(20)),
          const HSpace(4.0),
          Text(
            '${LocaleKeys.trash_text.tr()} / ${item.displayName}',
            style: theme.textStyle.body
                .standard(color: theme.textColorScheme.secondary),
          ),
        ],
      );
    } else {
      return BlocProvider(
        create: (context) => ViewAncestorBloc(item.id),
        child: BlocBuilder<ViewAncestorBloc, ViewAncestorState>(
          builder: (context, state) {
            final ancestors = state.ancestor.ancestors;
            List<String> displayPath = ancestors.map((e) => e.name).toList();
            if (ancestors.length > 2) {
              displayPath = [ancestors.first.name, '...', ancestors.last.name];
            }
            return Text(
              displayPath.join(' / '),
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.secondary),
            );
          },
        ),
      );
    }
  }

  Widget buildSummary(AppFlowyThemeData theme) {
    if (item.content.isEmpty) {
      return const SizedBox.shrink();
    }
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: buildHighLightSpan(
        content: item.content,
        normal: theme.textStyle.heading4
            .standard(color: theme.textColorScheme.secondary),
        highlight: theme.textStyle.heading4
            .standard(color: theme.textColorScheme.primary)
            .copyWith(
              backgroundColor: theme.fillColorScheme.themeSelect,
            ),
      ),
    );
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
    final splits = content.split(queryText);
    final List<String> contents = [];
    for (int i = 0; i < splits.length; i++) {
      contents.add(splits[i]);
      if (i != splits.length - 1) {
        contents.add(queryText);
      }
    }
    return TextSpan(
      children: List.generate(contents.length, (index) {
        final content = contents[index];
        final isHighlight = content == queryText;
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
