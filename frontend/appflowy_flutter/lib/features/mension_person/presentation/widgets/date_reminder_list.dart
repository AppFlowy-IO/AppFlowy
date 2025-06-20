import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/inline_actions/handlers/date_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/reminder_reference.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'item_visibility_detector.dart';

class DateReminderList extends StatelessWidget {
  const DateReminderList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        spacing = theme.spacing,
        itemMap = context.read<MentionItemMap>(),
        filterItems = buildItems(context);

    if (filterItems.isEmpty) return const SizedBox.shrink();
    final children = List.generate(filterItems.length, (index) {
      final item = filterItems[index];
      itemMap.addToDateAndReminder(item);
      return MentionMenuItenVisibilityDetector(
        id: item.id,
        child: AFTextMenuItem(
          title: item.id,
          selected: context.read<MentionBloc>().state.selectedId == item.id,
          onTap: item.onExecute,
          backgroundColor: context.mentionItemBGColor,
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AFDivider(),
        Padding(
          padding: EdgeInsets.all(spacing.m),
          child: AFMenuSection(
            title: LocaleKeys.document_mentionMenu_dateAndReminder.tr(),
            children: children,
          ),
        ),
      ],
    );
  }

  List<MentionMenuItem> buildItems(BuildContext context) {
    final mentionState = context.read<MentionBloc>().state,
        query = mentionState.query;
    final items = [
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateToday.tr(),
        onExecute: () => onDateInsert(context, DateTime.now()),
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateTomorrow.tr(),
        onExecute: () => onDateInsert(
          context,
          DateTime.now().add(const Duration(days: 1)),
        ),
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateYesterday.tr(),
        onExecute: () => onDateInsert(
          context,
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminderTomorrow9Am.tr(),
        onExecute: () {
          final now = DateTime.now();
          onReminderInsert(
            context,
            DateTime(now.year, now.month, now.day + 1, 9),
            true,
          );
        },
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminder1Week.tr(),
        onExecute: () => onReminderInsert(
          context,
          DateTime.now().add(const Duration(days: 7)),
          false,
        ),
      ),
    ];
    List<MentionMenuItem> filterItems = List.of(items);
    if (query.isNotEmpty) {
      filterItems = filterItems
          .where((item) => item.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    return filterItems;
  }

  Future<void> onDateInsert(
    BuildContext context,
    DateTime date,
  ) async {
    final mentionInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionInfo.editorState,
        query = context.read<MentionBloc>().state.query;
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) return;
    final range = mentionInfo.textRange(query);

    onDismiss(mentionInfo);
    await editorState.insertDateReference(date, range.start, range.end);
  }

  Future<void> onReminderInsert(
    BuildContext context,
    DateTime date,
    bool includeTime,
  ) async {
    final mentionInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionInfo.editorState,
        query = context.read<MentionBloc>().state.query;
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) return;

    final range = mentionInfo.textRange(query);
    onDismiss(mentionInfo);
    await editorState.insertReminderReference(
      context,
      date,
      range.start,
      range.end,
      includeTime: includeTime,
    );
  }

  void onDismiss(MentionMenuServiceInfo info) {
    info.onDismiss.call();
  }
}
