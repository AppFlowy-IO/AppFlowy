import 'package:appflowy/features/mension_person/data/models/invite.dart';
import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/features/mension_person/presentation/menu_extension.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/invite/invite_menu.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/invite/person_list_invite_item.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

import 'mobile_contact_detail_menu.dart';

void showMobileInviteMenu(BuildContext context) {
  final theme = AppFlowyTheme.of(context),
      documentBloc = context.read<DocumentBloc?>(),
      mentionBloc = context.read<MentionBloc>(),
      workspaceBloc = context.read<UserWorkspaceBloc?>(),
      serviceInfo = context.read<MentionMenuServiceInfo>(),
      editorState = serviceInfo.editorState,
      selection = editorState.selection;
  showMobileBottomSheet(
    context,
    dragHandleBuilder: (_) => const DragHandleV2(),
    showDragHandle: true,
    showDivider: false,
    backgroundColor: theme.surfaceColorScheme.primary,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: mentionBloc),
        if (documentBloc != null) BlocProvider.value(value: documentBloc),
        if (workspaceBloc != null) BlocProvider.value(value: workspaceBloc),
      ],
      child: MobileInviteMenu(
        info: InviteInfo(email: mentionBloc.state.query),
        onInfoChanged: (v) => editorState.onInviteInfoApply(
          inviteInfo: v,
          serviceInfo: serviceInfo,
          selection: selection,
          documentBloc: documentBloc,
          mentionBloc: mentionBloc,
        ),
      ),
    ),
  );
  serviceInfo.onDismiss.call();
}

class MobileInviteMenu extends StatefulWidget {
  const MobileInviteMenu({
    super.key,
    required this.info,
    required this.onInfoChanged,
  });

  final InviteInfo info;
  final ValueChanged<InviteInfo> onInfoChanged;

  @override
  State<MobileInviteMenu> createState() => _MobileInviteMenuState();
}

class _MobileInviteMenuState extends State<MobileInviteMenu> {
  late FocusNode emailFocusNode = FocusNode();
  late TextEditingController emailController =
      TextEditingController(text: info.email);

  late InviteInfo info = widget.info;
  final emailKey = GlobalKey<AFTextFieldState>();

  @override
  void initState() {
    super.initState();
    emailFocusNode.makeSureHasFocus(() => !mounted);
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildHeader(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildSubtitle(LocaleKeys.document_mentionMenu_email.tr()),
              VSpace(spacing.m),
              buildEmailField(),
              VSpace(spacing.xl),
              buildSubtitle(LocaleKeys.document_mentionMenu_type.tr()),
              VSpace(spacing.m),
              ...buildRoles(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHeader() {
    return BottomSheetHeader(
      showBackButton: false,
      showDoneButton: true,
      showCloseButton: true,
      showRemoveButton: false,
      title: LocaleKeys.document_mentionMenu_invitePerson.tr(),
      doneButtonBuilder: (context) {
        final theme = AppFlowyTheme.of(context);
        final isContact = info.role == PersonRole.contact;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onApply,
          child: Padding(
            padding: EdgeInsets.only(right: theme.spacing.xl),
            child: Text(
              isContact
                  ? LocaleKeys.button_next.tr()
                  : LocaleKeys.document_mentionMenu_invite.tr(),
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.action),
            ),
          ),
        );
      },
    );
  }

  Widget buildSubtitle(String title) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      title,
      style: theme.textStyle.caption.enhanced(
        color: theme.textColorScheme.secondary,
      ),
    );
  }

  Widget buildEmailField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: AFTextField(
        key: emailKey,
        size: AFTextFieldSize.m,
        focusNode: emailFocusNode,
        controller: emailController,
        hintText: LocaleKeys.document_mentionMenu_emailInputHint.tr(),
        onChanged: (text) {
          updateInfo(info.copyWith(email: text));
        },
      ),
    );
  }

  List<Widget> buildRoles() {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    final items = List.generate(PersonRole.values.length, (index) {
      final role = PersonRole.values[index];
      return _RoleItem(
        selected: info.role == role,
        role: role,
        onTap: () => updateInfo(info.copyWith(role: role)),
      );
    });
    final List<Widget> results = [];
    for (int i = 0; i < items.length; i++) {
      results.add(items[i]);
      if (i != items.length - 1) results.add(VSpace(spacing.m));
    }
    return results;
  }

  void updateInfo(InviteInfo newInfo) {
    if (mounted) {
      setState(() {
        info = newInfo;
      });
    }
  }

  void onApply() {
    final isContact = info.role == PersonRole.contact;
    final email = info.email.trim();
    if (email.isEmpty || !isEmail(email)) {
      emailKey.currentState?.syncError(
        errorText: LocaleKeys.document_mentionMenu_emailInputError.tr(),
      );
      return;
    }
    emailKey.currentState?.clearError();
    if (isContact) {
      showMobileContactDetailMenu(
        context: context,
        info: info,
        onInfoChanged: (v) {
          Navigator.pop(context);
          widget.onInfoChanged.call(v);
        },
      );
    } else {
      widget.onInfoChanged.call(info);
      Navigator.pop(context);
    }
  }
}

class _RoleItem extends StatelessWidget {
  const _RoleItem({
    required this.selected,
    required this.role,
    required this.onTap,
  });
  final bool selected;
  final PersonRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(spacing.m),
          border: Border.all(
            color: selected
                ? theme.borderColorScheme.themeThick
                : theme.borderColorScheme.primary,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing.l,
            horizontal: spacing.xl,
          ),
          child: Row(
            children: [
              selected
                  ? FlowySvg(
                      FlowySvgs.radio_button_selected_m,
                      blendMode: null,
                      size: Size.square(20),
                    )
                  : FlowySvg(
                      FlowySvgs.radio_button_unselected_m,
                      color: theme.borderColorScheme.primary,
                      size: Size.square(20),
                    ),
              HSpace(spacing.l),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    role.displayName,
                    style: theme.textStyle.body
                        .enhanced(color: theme.textColorScheme.primary),
                  ),
                  Text(
                    role.description,
                    style: theme.textStyle.caption
                        .standard(color: theme.textColorScheme.secondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
