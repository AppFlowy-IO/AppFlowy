import 'package:appflowy/date/date_service.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/service_handler.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

final _keywords = [
  LocaleKeys.inlineActions_date.tr().toLowerCase(),
];

class DateReferenceService extends InlineActionsDelegate {
  DateReferenceService(this.context) {
    // Initialize locale
    _locale = context.locale.toLanguageTag();

    // Initializes options
    _setOptions();
  }

  final BuildContext context;

  late String _locale;
  late List<InlineActionsMenuItem> _allOptions;

  List<InlineActionsMenuItem> options = [];

  @override
  Future<InlineActionsResult> search([
    String? search,
  ]) async {
    // Checks if Locale has changed since last
    _setLocale();

    // Filters static options
    _filterOptions(search);

    // Searches for date by pattern
    _searchDate(search);

    // Searches for date by natural language prompt
    await _searchDateNLP(search);

    return InlineActionsResult(
      title: LocaleKeys.inlineActions_date.tr(),
      results: options,
    );
  }

  void _filterOptions(String? search) {
    if (search == null || search.isEmpty) {
      options = _allOptions;
      return;
    }

    options = _allOptions
        .where(
          (option) =>
              option.keywords != null &&
              option.keywords!.isNotEmpty &&
              option.keywords!.any(
                (keyword) => keyword.contains(search.toLowerCase()),
              ),
        )
        .toList();

    if (options.isEmpty && _keywords.any((k) => search.startsWith(k))) {
      _setOptions();
      options = _allOptions;
    }
  }

  void _searchDate(String? search) {
    if (search == null || search.isEmpty) {
      return;
    }

    try {
      final date = DateFormat.yMd(_locale).parse(search);
      options.insert(0, _itemFromDate(date));
    } catch (_) {
      return;
    }
  }

  Future<void> _searchDateNLP(String? search) async {
    if (search == null || search.isEmpty) {
      return;
    }

    final result = await DateService.queryDate(search);

    result.fold(
      (date) => options.insert(0, _itemFromDate(date)),
      (_) {},
    );
  }

  Future<void> _insertDateReference(
    EditorState editorState,
    DateTime date,
    int start,
    int end,
  ) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final transaction = editorState.transaction
      ..replaceText(
        node,
        start,
        end,
        MentionBlockKeys.mentionChar,
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.date.name,
            MentionBlockKeys.date: date.toIso8601String(),
          },
        },
      );

    await editorState.apply(transaction);
  }

  void _setOptions() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    _allOptions = [
      _itemFromDate(
        today,
        LocaleKeys.relativeDates_today.tr(),
        [DateFormat.yMd(_locale).format(today)],
      ),
      _itemFromDate(
        tomorrow,
        LocaleKeys.relativeDates_tomorrow.tr(),
        [DateFormat.yMd(_locale).format(tomorrow)],
      ),
      _itemFromDate(
        yesterday,
        LocaleKeys.relativeDates_yesterday.tr(),
        [DateFormat.yMd(_locale).format(yesterday)],
      ),
    ];
  }

  /// Sets Locale on each search to make sure
  /// keywords are localized
  void _setLocale() {
    final locale = context.locale.toLanguageTag();

    if (locale != _locale) {
      _locale = locale;
      _setOptions();
    }
  }

  InlineActionsMenuItem _itemFromDate(
    DateTime date, [
    String? label,
    List<String>? keywords,
  ]) {
    final labelStr = label ?? DateFormat.yMd(_locale).format(date);

    return InlineActionsMenuItem(
      label: labelStr.capitalize(),
      keywords: [labelStr.toLowerCase(), ...?keywords],
      onSelected: (context, editorState, menuService, replace) =>
          _insertDateReference(
        editorState,
        date,
        replace.$1,
        replace.$2,
      ),
    );
  }
}
