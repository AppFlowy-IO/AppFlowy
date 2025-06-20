import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class ProfileCardMoreButton extends StatelessWidget {
  const ProfileCardMoreButton({
    super.key,
    this.onEnter,
    this.onExit,
    required this.popoverController,
  });

  final PointerEnterEventListener? onEnter;
  final PointerExitEventListener? onExit;
  final PopoverController popoverController;

  @override
  Widget build(BuildContext context) {
    final personBloc = context.read<PersonBloc>(),
        person = personBloc.state.person;
    if (person.isEmpty) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context);

    return AppFlowyPopover(
      offset: Offset(0, -2),
      direction: UniversalPlatform.isMobile
          ? PopoverDirection.topWithRightAligned
          : PopoverDirection.topWithLeftAligned,
      margin: EdgeInsets.zero,
      controller: popoverController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      popoverDecoration: BoxDecoration(),
      popupBuilder: (context) => BlocProvider.value(
        value: personBloc,
        child: BlocBuilder<PersonBloc, PersonState>(
          builder: (ctx, state) => MouseRegion(
            onEnter: onEnter,
            onExit: onExit,
            child: _Menu(),
          ),
        ),
      ),
      child: AFOutlinedButton.normal(
        backgroundColor: (context, isHovering, disabled) {
          final theme = AppFlowyTheme.of(context);
          if (isHovering) {
            return theme.fillColorScheme.contentHover;
          }
          return theme.fillColorScheme.content;
        },
        padding:
            EdgeInsets.all(UniversalPlatform.isMobile ? 10 : theme.spacing.s),
        builder: (context, hovering, disabled) {
          return FlowySvg(
            FlowySvgs.mention_more_results_m,
            size: Size.square(20),
            color: theme.iconColorScheme.primary,
          );
        },
        onTap: show,
      ),
    );
  }

  void show() {
    popoverController.show();
  }

  void hide() {
    popoverController.close();
  }
}

class _Menu extends StatelessWidget {
  const _Menu();

  @override
  Widget build(BuildContext context) {
    final personBloc = context.read<PersonBloc>(),
        person = personBloc.state.person;
    if (person.isEmpty) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context);
    final role = person.role;
    List<Widget> children = [];
    if (role == PersonRole.member) {
      children = buildMemberItems(person, context);
    } else if (role == PersonRole.guest) {
      children = buildGuestItems(person, context);
    } else {
      children = buildContactItems(person, context);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surfaceColorScheme.layer04,
        borderRadius: BorderRadius.circular(theme.borderRadius.l),
        boxShadow: theme.shadow.small,
      ),
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  List<Widget> buildMemberItems(Person person, BuildContext context) {
    final userProfile = context.read<UserWorkspaceBloc?>()?.state.userProfile;
    final isMyself = userProfile?.email == person.email;
    return [
      AFMenuItem(
        title:
            context._title(LocaleKeys.document_mentionMenu_shareProfile.tr()),
        onTap: () {},
      ),
      AFMenuItem(
        title: context._title(LocaleKeys.document_mentionMenu_sendEmail.tr()),
        onTap: () {},
      ),
      if (isMyself)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_editInfomation.tr()),
          onTap: () {},
        ),
      if (isMyself)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_changeCoverImage.tr()),
          onTap: () {},
        ),
    ];
  }

  List<Widget> buildGuestItems(Person person, BuildContext context) {
    final userProfile = context.read<UserWorkspaceBloc?>()?.state.userProfile;
    final isMyself = userProfile?.email == person.email;
    return [
      AFMenuItem(
        title:
            context._title(LocaleKeys.document_mentionMenu_shareProfile.tr()),
        onTap: () {},
      ),
      AFMenuItem(
        title: context._title(LocaleKeys.document_mentionMenu_sendEmail.tr()),
        onTap: () {},
      ),
      AFMenuItem(
        title: context
            ._title(LocaleKeys.document_mentionMenu_convertToAMenber.tr()),
        onTap: () {},
      ),
      if (isMyself)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_editInfomation.tr()),
          onTap: () {},
        ),
      if (isMyself)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_changeCoverImage.tr()),
          onTap: () {},
        ),
    ];
  }

  List<Widget> buildContactItems(Person person, BuildContext context) {
    final invited = person.invited == true;
    return [
      AFMenuItem(
        title:
            context._title(LocaleKeys.document_mentionMenu_shareProfile.tr()),
        onTap: () {},
      ),
      if (!invited)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_inviteAsMember.tr()),
          onTap: () {},
        ),
      if (!invited)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_inviteAsGuest.tr()),
          onTap: () {},
        ),
      AFMenuItem(
        title: context
            ._title(LocaleKeys.document_mentionMenu_editContactInfomation.tr()),
        onTap: () {},
      ),
      if (invited)
        AFMenuItem(
          title: context
              ._title(LocaleKeys.document_mentionMenu_changeCoverImage.tr()),
          onTap: () {},
        ),
    ];
  }
}

extension ProfileCardMenuContextExtension on BuildContext {
  Widget _title(String title) {
    final theme = AppFlowyTheme.of(this);
    return Text(
      title,
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
    );
  }
}
