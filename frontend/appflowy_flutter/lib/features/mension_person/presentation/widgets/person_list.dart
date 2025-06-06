import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'item_visibility_detector.dart';
import 'more_results_item.dart';

class PersonList extends StatelessWidget {
  const PersonList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<MentionBloc>().state,
        itemMap = context.read<MentionItemMap>();
    final persons = state.persons, showMorePersons = state.showMorePersons;
    final hasMorePersons = persons.length > 4;
    final showMoreResult = !showMorePersons && hasMorePersons;
    List<Person> displayPersons = List.of(persons);
    if (showMoreResult) {
      displayPersons = persons.sublist(0, 4);
    }

    for (final person in displayPersons) {
      itemMap.addToPerson(
        MentionMenuItem(
          id: person.id,
          onExecute: () => onPersonSelected(person, context),
        ),
      );
    }

    final id = LocaleKeys.document_mentionMenu_moreResults
        .tr(args: ['show more person']);
    void onShowMore() {
      if (!showMoreResult) return;
      context
          .read<MentionBloc>()
          .add(MentionEvent.showMorePersons(persons[4].id));
    }

    if (showMoreResult) {
      itemMap.addToPerson(MentionMenuItem(id: id, onExecute: onShowMore));
    }

    return AFMenuSection(
      title: LocaleKeys.document_mentionMenu_people.tr(),
      titleTrailing: sendNotificationSwitch(context),
      children: [
        ...List.generate(displayPersons.length, (index) {
          final person = displayPersons[index];
          return MentionMenuItenVisibilityDetector(
            id: person.id,
            child: AFTextMenuItem(
              leading: AFAvatar(url: person.avatarUrl, size: AFAvatarSize.s),
              selected: state.selectedId == person.id,
              title: person.name,
              subtitle: person.email,
              backgroundColor: context.mentionItemBGColor,
              onTap: () => onPersonSelected(person, context),
            ),
          );
        }),
        if (showMoreResult)
          MoreResultsItem(num: persons.length - 4, onTap: onShowMore, id: id),
      ],
    );
  }

  Widget sendNotificationSwitch(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final bloc = context.read<MentionBloc>(), state = bloc.state;

    return Row(
      children: [
        Text(
          LocaleKeys.document_mentionMenu_sendNotification.tr(),
          style: theme.textStyle.caption
              .standard(color: theme.textColorScheme.secondary)
              .copyWith(letterSpacing: 0.1),
        ),
        SizedBox(width: 4),
        Toggle(
          value: state.sendNotification,
          style: ToggleStyle(width: 34, height: 18, thumbRadius: 17),
          padding: EdgeInsets.zero,
          inactiveBackgroundColor: theme.fillColorScheme.secondary,
          onChanged: (v) {
            bloc.add(MentionEvent.toggleSendNotification());
          },
        ),
      ],
    );
  }

  Future<void> onPersonSelected(
    Person person,
    BuildContext context,
  ) async {
    final mentionInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionInfo.editorState,
        mentionBloc = context.read<MentionBloc>(),
        documentBloc = context.read<DocumentBloc>(),
        mentionState = mentionBloc.state,
        query = mentionState.query;
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) return;

    final range = mentionInfo.textRange(query);
    mentionInfo.onDismiss.call();
    await editorState.insertPerson(
      person,
      documentBloc.documentId,
      range,
      mentionState.sendNotification,
    );
  }
}

extension PersonListEditorStateExtension on EditorState {
  Future<void> insertPerson(
    Person person,
    String pageId,
    TextRange range,
    bool sendNotification,
  ) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) return;

    final transaction = this.transaction
      ..replaceText(
        node,
        range.start,
        range.end,
        MentionBlockKeys.mentionChar,
        attributes: MentionBlockKeys.buildMentionPersonAttributes(
          personId: person.id,
          pageId: pageId,
        ),
      );

    await apply(transaction);
  }
}
