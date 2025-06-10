import 'package:appflowy/features/mension_person/data/models/models.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:string_validator/string_validator.dart';

import 'contact_detail_menu.dart';

class PersonRoleDownMenuItem with AFDropDownMenuMixin {
  const PersonRoleDownMenuItem({
    required this.role,
  });

  final PersonRole role;

  @override
  String get label => role.displayName;
}

class InviteMenu extends StatefulWidget {
  const InviteMenu({
    super.key,
    required this.info,
    required this.onInfoChanged,
  });

  final InviteInfo info;
  final ValueChanged<InviteInfo> onInfoChanged;

  @override
  State<InviteMenu> createState() => _InviteMenuState();
}

class _InviteMenuState extends State<InviteMenu> {
  late FocusNode emailFocusNode = FocusNode(onKeyEvent: onFocusKeyEvent);
  late FocusScopeNode menuFocusNode =
      FocusScopeNode(onKeyEvent: onFocusKeyEvent);
  late TextEditingController emailController =
      TextEditingController(text: info.email);

  late InviteInfo info = widget.info;
  final emailKey = GlobalKey<AFTextFieldState>();

  @override
  void initState() {
    super.initState();
    makeSureHasFocus();
  }

  @override
  void dispose() {
    emailController.dispose();
    emailFocusNode.dispose();
    menuFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return GestureDetector(
      onTap: () {},
      child: FocusScope(
        node: menuFocusNode,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: 400, maxWidth: 400, minWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surfaceColorScheme.layer02,
              borderRadius: BorderRadius.circular(spacing.xl),
              boxShadow: theme.shadow.medium,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: spacing.xl,
                horizontal: spacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildTitle(context),
                  VSpace(spacing.l),
                  buildSubtitle(
                    context,
                    LocaleKeys.document_mentionMenu_email.tr(),
                  ),
                  VSpace(spacing.xs),
                  buildEmailField(),
                  VSpace(spacing.l),
                  buildSubtitle(
                    context,
                    LocaleKeys.document_mentionMenu_type.tr(),
                  ),
                  VSpace(spacing.xs),
                  buildRoleSelector(),
                  VSpace(spacing.xxl),
                  Row(
                    children: [
                      Spacer(),
                      buildBackButton(),
                      HSpace(spacing.l),
                      buildAddButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      LocaleKeys.document_mentionMenu_invitePerson.tr(),
      style: theme.textStyle.heading4.prominent(
        color: theme.textColorScheme.primary,
      ),
    );
  }

  Widget buildSubtitle(BuildContext context, String title) {
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
      width: 360,
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

  Widget buildRoleSelector() {
    return SizedBox(
      width: 360,
      child: AFDropDownMenu<PersonRoleDownMenuItem>(
        items: roleItems(),
        selectedItems: [info.role.buildItem()],
        itemBuilder: (context, item, isSelected, onSelected) =>
            buildRoleItem(context, item, onSelected),
        onSelected: (value) {
          updateInfo(info.copyWith(role: value?.role));
        },
      ),
    );
  }

  Widget buildRoleItem(
    BuildContext context,
    PersonRoleDownMenuItem item,
    ValueChanged<PersonRoleDownMenuItem>? onSelected,
  ) {
    final theme = AppFlowyTheme.of(context);
    final isSelected = info.role == item.role;
    return AFBaseButton(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      borderRadius: theme.borderRadius.m,
      borderColor: (context, isHovering, disabled, isFocused) {
        return Colors.transparent;
      },
      showFocusRing: false,
      builder: (context, _, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.role.displayName,
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.primary),
            ),
            Text(
              item.role.description,
              style: theme.textStyle.caption
                  .standard(color: theme.textColorScheme.secondary),
            ),
          ],
        );
      },
      backgroundColor: (context, isHovering, _) {
        if (isHovering || isSelected) {
          return theme.fillColorScheme.contentHover;
        }
        return Colors.transparent;
      },
      onTap: () => onSelected?.call(item),
    );
  }

  Widget buildBackButton() {
    return AFOutlinedTextButton.normal(
      text: LocaleKeys.document_mentionMenu_back.tr(),
      onTap: onBack,
    );
  }

  Widget buildAddButton() {
    final isContact = info.role == PersonRole.contact;
    return AFFilledTextButton.primary(
      text: isContact
          ? LocaleKeys.button_add.tr()
          : LocaleKeys.document_mentionMenu_invite.tr(),
      onTap: onApply,
    );
  }

  List<PersonRoleDownMenuItem> roleItems() =>
      PersonRole.values.map((role) => role.buildItem()).toList();

  void onBack() {
    final serviceInfo = context.read<MentionMenuServiceInfo?>();
    if (serviceInfo == null) return;
    serviceInfo.onMenuReplace.call(
      MentionMenuBuilderInfo(
        builder: (service, lrbt) => service.buildMultiBlocProvider(
          (_) => Provider.value(
            value: serviceInfo,
            child: MentionMenu(),
          ),
        ),
        menuSize: Size.square(400),
      ),
    );
  }

  Future<void> makeSureHasFocus() async {
    final focusNode = emailFocusNode;
    if (!mounted || focusNode.hasFocus) return;
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      makeSureHasFocus();
    });
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
      final serviceInfo = context.read<MentionMenuServiceInfo?>();
      if (serviceInfo == null) return;
      serviceInfo.onMenuReplace.call(
        MentionMenuBuilderInfo(
          builder: (service, lrbt) => service.buildMultiBlocProvider(
            (_) => Provider.value(
              value: serviceInfo,
              child: ContactDetailMenu(
                info: info,
                onInfoChanged: widget.onInfoChanged,
              ),
            ),
          ),
          menuSize: Size(400, 300),
        ),
      );
    } else {
      widget.onInfoChanged.call(info);
    }
  }

  void onDismiss() {
    emailFocusNode.unfocus();
    menuFocusNode.unfocus();
    final mentionInfo = context.read<MentionMenuServiceInfo?>();
    mentionInfo?.onDismiss.call();
  }

  KeyEventResult onFocusKeyEvent(FocusNode node, KeyEvent key) {
    if (key is! KeyDownEvent) return KeyEventResult.ignored;
    if (key.logicalKey == LogicalKeyboardKey.escape) {
      onDismiss();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

extension PersonRoleExtension on PersonRole {
  PersonRoleDownMenuItem buildItem() {
    return PersonRoleDownMenuItem(role: this);
  }

  String get displayName {
    switch (this) {
      case PersonRole.member:
        return LocaleKeys.document_mentionMenu_member.tr();
      case PersonRole.guest:
        return LocaleKeys.document_mentionMenu_guest.tr();
      case PersonRole.contact:
        return LocaleKeys.document_mentionMenu_contact.tr();
    }
  }

  String get description {
    switch (this) {
      case PersonRole.member:
        return LocaleKeys.document_mentionMenu_memberDescription.tr();
      case PersonRole.guest:
        return LocaleKeys.document_mentionMenu_guestDescription.tr();
      case PersonRole.contact:
        return LocaleKeys.document_mentionMenu_contactDescription.tr();
    }
  }
}
