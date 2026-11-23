import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SearchResultTypeSelector extends StatelessWidget {
  const SearchResultTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final SearchResultType value;
  final ValueChanged<SearchResultType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return PopupMenuButton<SearchResultType>(
      initialValue: value,
      onSelected: onChanged,
      position: PopupMenuPosition.under,
      tooltip: LocaleKeys.search_filterByContentType.tr(),
      itemBuilder: (context) => [
        for (final type in SearchResultType.values)
          CheckedPopupMenuItem(
            value: type,
            checked: type == value,
            child: Text(_label(type)),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, maxWidth: 180),
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: theme.borderColorScheme.primary),
          borderRadius: BorderRadius.circular(theme.spacing.l),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _label(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.body
                    .standard(color: theme.textColorScheme.primary),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: theme.iconColorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  String _label(SearchResultType type) => switch (type) {
        SearchResultType.all => LocaleKeys.search_allContentTypes.tr(),
        SearchResultType.documents => LocaleKeys.search_documents.tr(),
        SearchResultType.databases => LocaleKeys.search_databases.tr(),
      };
}
