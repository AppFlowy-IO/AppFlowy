import 'package:appflowy/features/mension_person/data/models/models.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_list.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../item_visibility_detector.dart';
import 'invite_menu.dart';

class PersonListInviteItem extends StatelessWidget {
  const PersonListInviteItem({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<MentionBloc>().state,
        query = state.query,
        itemMap = context.read<MentionItemMap>();
    final id = LocaleKeys.document_mentionMenu_add.tr(args: ['add person']);
    final displayQuery = query.isEmpty ? '' : ' "$query"';
    itemMap.addToPerson(
      MentionMenuItem(id: id, onExecute: () => invitePerson(context)),
    );
    return MentionMenuItenVisibilityDetector(
      id: id,
      child: AFTextMenuItem(
        selected: state.selectedId == id,
        leading: SizedBox.square(
          dimension: 24,
          child: Center(
            child: FlowySvg(
              FlowySvgs.mention_invite_user_m,
              size: const Size.square(20.0),
            ),
          ),
        ),
        title: LocaleKeys.document_mentionMenu_add.tr(args: [displayQuery]),
        backgroundColor: context.mentionItemBGColor,
        onTap: () => invitePerson(context),
      ),
    );
  }

  void invitePerson(BuildContext context) {
    final serviceInfo = context.read<MentionMenuServiceInfo>(),
        documentBloc = context.read<DocumentBloc?>();
    final mentionBloc = context.read<MentionBloc>(),
        mentionState = mentionBloc.state,
        query = mentionState.query;

    serviceInfo.onMenuReplace.call(
      MentionMenuBuilderInfo(
        builder: (service, lrbt) => service.buildMultiBlocProvider(
          (_) => Provider.value(
            value: serviceInfo,
            child: InviteMenu(
              info: InviteInfo(email: query),
              onInfoChanged: (v) async {
                final editorState = serviceInfo.editorState;
                final selection = editorState.selection;
                if (selection == null ||
                    !selection.isCollapsed ||
                    documentBloc == null) {
                  return;
                }
                final node = editorState.getNodeAtPath(selection.end.path);
                final delta = node?.delta;
                if (node == null || delta == null) return;
                final range = serviceInfo.textRange(query);
                await (await mentionBloc.repository.invitePerson(
                  workspaceId: mentionBloc.workspaceId,
                  info: v,
                ))
                    .fold((person) async {
                  serviceInfo.onDismiss.call();
                  await editorState.insertPerson(
                    person,
                    documentBloc.documentId,
                    range,
                    mentionState.sendNotification,
                  );
                  final isContact = person.role == PersonRole.contact;
                  if (isContact) {
                    showToastNotification(
                      message: LocaleKeys.document_mentionMenu_addContactToast
                          .tr(args: [person.name]),
                    );
                  } else {
                    showToastNotification(
                      message:
                          LocaleKeys.document_mentionMenu_inviteEmailSent.tr(),
                    );
                  }
                }, (error) {
                  showToastNotification(
                    message: error.msg,
                    type: ToastificationType.error,
                  );
                });
              },
            ),
          ),
        ),
        menuSize: Size(400, 400),
      ),
    );
  }
}
