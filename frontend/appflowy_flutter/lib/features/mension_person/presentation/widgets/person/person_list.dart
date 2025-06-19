import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
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
import 'package:universal_platform/universal_platform.dart';

import '../invite/person_list_invite_item.dart';
import '../item_visibility_detector.dart';
import '../more_results_item.dart';
import 'person_tooltip.dart';

class PersonList extends StatelessWidget {
  const PersonList({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<MentionBloc>().state,
        itemMap = context.read<MentionItemMap>(),
        userWorkspaceBloc = context.read<UserWorkspaceBloc?>(),
        theme = AppFlowyTheme.of(context),
        spacing = theme.spacing;
        
    if (userWorkspaceBloc == null) return const SizedBox.shrink();
    final workspaceType =
            userWorkspaceBloc.state.currentWorkspace?.workspaceType,
        userState = userWorkspaceBloc.userProfile;

    if (workspaceType == WorkspaceTypePB.LocalW) return const SizedBox.shrink();
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
      context.read<MentionBloc>().add(
            MentionEvent.showMorePersons(
              UniversalPlatform.isMobile ? '' : persons[4].id,
            ),
          );
    }

    if (showMoreResult) {
      itemMap.addToPerson(MentionMenuItem(id: id, onExecute: onShowMore));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(spacing.m),
          child: AFMenuSection(
            title: LocaleKeys.document_mentionMenu_people.tr(),
            titleTrailing: sendNotificationSwitch(context),
            children: [
              ...List.generate(displayPersons.length, (index) {
                final person = displayPersons[index];
                final isCurrentUser = person.email == userState.email;
                return MentionMenuItenVisibilityDetector(
                  id: person.id,
                  child: PersonToolTip(
                    isMyself: isCurrentUser,
                    person: person,
                    child: AFTextMenuItem(
                      leading:
                          AFAvatar(url: person.avatarUrl, size: AFAvatarSize.s),
                      selected: state.selectedId == person.id,
                      title: person.name,
                      subtitle: person.email,
                      backgroundColor: context.mentionItemBGColor,
                      onTap: () => onPersonSelected(person, context),
                    ),
                  ),
                );
              }),
              if (showMoreResult)
                MoreResultsItem(
                  num: persons.length - 4,
                  onTap: onShowMore,
                  id: id,
                ),
              PersonListInviteItem(),
            ],
          ),
        ),
        AFDivider(),
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
          duration: Duration.zero,
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
      selection,
    );
  }
}

extension PersonListEditorStateExtension on EditorState {
  Future<void> insertPerson(
    Person person,
    String pageId,
    TextRange range,
    bool sendNotification,
    Selection? selection,
  ) async {
    final mSelection = selection ?? this.selection;
    if (mSelection == null || !mSelection.isCollapsed) return;

    final node = getNodeAtPath(mSelection.start.path);
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
