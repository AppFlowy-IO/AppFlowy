import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
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
    final serviceInfo = context.read<MentionMenuServiceInfo>();
    final state = context.read<MentionBloc>().state, query = state.query;
    serviceInfo.onMenuReplace.call(
      MentionMenuBuilderInfo(
        builder: (service, lrbt) => service.buildMultiBlocProvider(
          (_) => Provider.value(
            value: serviceInfo,
            child: InviteMenu(
              info: InviteMenuInfo(email: query),
              onInfoChanged: (v) {},
            ),
          ),
        ),
        menuSize: Size(400, 400),
      ),
    );
  }
}
