import 'package:flutter/material.dart';

class MentionMenuItem {
  MentionMenuItem({required this.onExecute, required this.id});

  final String id;
  final VoidCallback onExecute;
}

enum MentionMenuType {
  person,
  page,
  dateAndReminder,
}

class MentionItemMap {
  final Map<MentionMenuType, List<MentionMenuItem>> _map = {
    MentionMenuType.person: [],
    MentionMenuType.page: [],
    MentionMenuType.dateAndReminder: [],
  };

  void addToPerson(MentionMenuItem item) {
    final items = _map[MentionMenuType.person] ?? [];
    items.add(item);
    _map[MentionMenuType.person] = items;
  }

  void addToPage(MentionMenuItem item) {
    final items = _map[MentionMenuType.page] ?? [];
    items.add(item);
    _map[MentionMenuType.page] = items;
  }

  void addToDateAndReminder(MentionMenuItem item) {
    final items = _map[MentionMenuType.dateAndReminder] ?? [];
    items.add(item);
    _map[MentionMenuType.dateAndReminder] = items;
  }

  List<MentionMenuItem> get items =>
      _map.values.expand((items) => items).toList();
}
