import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'item_visibility_detector.dart';

class DateReminderList extends StatelessWidget {
  const DateReminderList({super.key});

  @override
  Widget build(BuildContext context) {
    final mentionState = context.read<MentionBloc>().state,
        query = mentionState.query,
        itemMap = context.read<MentionItemMap>();
    final items = [
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateToday.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateTomorrow.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_dateYesterday.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminderTomorrow9Am.tr(),
        onExecute: () {},
      ),
      MentionMenuItem(
        id: LocaleKeys.document_mentionMenu_reminder1Week.tr(),
        onExecute: () {},
      ),
    ];
    List<MentionMenuItem> filterItems = List.of(items);
    if (query.isNotEmpty) {
      filterItems = filterItems
          .where((item) => item.id.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

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

    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_dateAndReminder.tr(),
      children: children,
    );
  }
}
