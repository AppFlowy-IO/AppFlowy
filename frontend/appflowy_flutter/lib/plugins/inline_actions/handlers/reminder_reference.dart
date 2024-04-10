import 'package:appflowy/date/date_service.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/service_handler.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/nanoid.dart';

final _keywords = [
  LocaleKeys.inlineActions_reminder_groupTitle.tr().toLowerCase(),
  LocaleKeys.inlineActions_reminder_shortKeyword.tr().toLowerCase(),
];

class ReminderReferenceService extends InlineActionsDelegate {
  ReminderReferenceService(this.context) {
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

    return _groupFromResults(options);
  }

  InlineActionsResult _groupFromResults([
    List<InlineActionsMenuItem>? options,
  ]) =>
      InlineActionsResult(
        title: LocaleKeys.inlineActions_reminder_groupTitle.tr(),
        results: options ?? [],
        startsWithKeywords: [
          LocaleKeys.inlineActions_reminder_groupTitle.tr().toLowerCase(),
          LocaleKeys.inlineActions_reminder_shortKeyword.tr().toLowerCase(),
        ],
      );

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
      (date) {
        // Only insert dates in the future
        if (DateTime.now().isBefore(date)) {
          options.insert(0, _itemFromDate(date));
        }
      },
      (_) {},
    );
  }

  Future<void> _insertReminderReference(
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

    final viewId = context.read<DocumentBloc>().view.id;
    final reminder = _reminderFromDate(date, viewId, node);

    final transaction = editorState.transaction
      ..replaceText(
        node,
        start,
        end,
        '\$',
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.date.name,
            MentionBlockKeys.date: date.toIso8601String(),
            MentionBlockKeys.reminderId: reminder.id,
            MentionBlockKeys.reminderOption: ReminderOption.atTimeOfEvent.name,
          },
        },
      );

    await editorState.apply(transaction);

    if (context.mounted) {
      context.read<ReminderBloc>().add(ReminderEvent.add(reminder: reminder));
    }
  }

  void _setOptions() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final oneWeek = today.add(const Duration(days: 7));

    _allOptions = [
      _itemFromDate(
        tomorrow,
        LocaleKeys.relativeDates_tomorrow.tr(),
        [DateFormat.yMd(_locale).format(tomorrow)],
      ),
      _itemFromDate(
        oneWeek,
        LocaleKeys.relativeDates_oneWeek.tr(),
        [DateFormat.yMd(_locale).format(oneWeek)],
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
          _insertReminderReference(editorState, date, replace.$1, replace.$2),
    );
  }

  ReminderPB _reminderFromDate(DateTime date, String viewId, Node node) {
    return ReminderPB(
      id: nanoid(),
      objectId: viewId,
      title: LocaleKeys.reminderNotification_title.tr(),
      message: LocaleKeys.reminderNotification_message.tr(),
      meta: {
        ReminderMetaKeys.includeTime: false.toString(),
        ReminderMetaKeys.blockId: node.id,
      },
      scheduledAt: Int64(date.millisecondsSinceEpoch ~/ 1000),
      isAck: date.isBefore(DateTime.now()),
    );
  }
}
