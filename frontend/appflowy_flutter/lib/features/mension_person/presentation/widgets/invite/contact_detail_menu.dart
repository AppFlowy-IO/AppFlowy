import 'package:appflowy/features/mension_person/data/models/models.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:appflowy/features/mension_person/presentation/menu_extension.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'invite_menu.dart';

class ContactDetailMenu extends StatefulWidget {
  const ContactDetailMenu({
    super.key,
    required this.info,
    required this.query,
    required this.onInfoChanged,
  });

  final InviteInfo info;
  final String query;
  final ValueChanged<InviteInfo> onInfoChanged;

  @override
  State<ContactDetailMenu> createState() => _ContactDetailMenuState();
}

class _ContactDetailMenuState extends State<ContactDetailMenu> {
  late final ContactDetailMenuState menuState = ContactDetailMenuState(
    nameFocusNode: FocusNode(onKeyEvent: onFocusKeyEvent),
    emailFocusNode: FocusNode(onKeyEvent: onFocusKeyEvent),
    menuFocusNode: FocusScopeNode(onKeyEvent: onFocusKeyEvent),
    nameController: TextEditingController(),
    emailController: TextEditingController(text: widget.info.email),
    descriptionController: TextEditingController(
      text: widget.info.contactDetail?.description ?? '',
    ),
    info: widget.info,
    detail: widget.info.contactDetail ?? ContactDetail(),
  );

  InviteInfo get info => menuState.info;

  @override
  void initState() {
    super.initState();
    menuState.nameFocusNode.makeSureHasFocus(() => !mounted);
  }

  @override
  void dispose() {
    menuState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return FocusScope(
      node: menuState.menuFocusNode,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 400,
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
                  buildTitle(),
                  VSpace(spacing.l),
                  buildSubtitle(LocaleKeys.document_mentionMenu_email.tr()),
                  VSpace(spacing.xs),
                  buildEmailField(),
                  buildSubtitle(LocaleKeys.document_mentionMenu_name.tr()),
                  VSpace(spacing.xs),
                  buildNameField(),
                  VSpace(spacing.xxl),
                  buildSubtitle(
                    LocaleKeys.document_mentionMenu_aboutContact.tr(),
                  ),
                  VSpace(spacing.xs),
                  buildDescriptionField(),
                  VSpace(spacing.xxl),
                  Row(
                    children: [
                      Spacer(),
                      buildBackButton(),
                      HSpace(spacing.l),
                      buildApplyButton(),
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

  Widget buildTitle() {
    final theme = AppFlowyTheme.of(context);
    return Text(
      LocaleKeys.document_mentionMenu_contactDetail.tr(),
      style: theme.textStyle.heading4
          .prominent(color: theme.textColorScheme.primary),
    );
  }

  Widget buildSubtitle(String title) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      title,
      style: theme.textStyle.caption
          .enhanced(color: theme.textColorScheme.secondary),
    );
  }

  Widget buildEmailField() {
    return SizedBox(
      width: 360,
      child: menuState.buildEmailField(
        onChanged: (text) => updateInfo(info.copyWith(email: text)),
      ),
    );
  }

  Widget buildNameField() {
    return SizedBox(
      width: 360,
      child: menuState.buildNameField(
        onChanged: (text) {
          final detail = menuState.detail.copyWith(name: text);
          updateInfo(info.copyWith(contactDetail: () => detail));
        },
      ),
    );
  }

  Widget buildDescriptionField() {
    return SizedBox(
      width: 360,
      height: 68,
      child: menuState.buildDescriptionField(
        onChanged: (text) {
          final detail = menuState.detail.copyWith(description: text);
          updateInfo(info.copyWith(contactDetail: () => detail));
        },
      ),
    );
  }

  Widget buildBackButton() {
    return AFOutlinedTextButton.normal(
      text: LocaleKeys.document_mentionMenu_back.tr(),
      backgroundFocusColor: (context, isHovering, isFocused, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.content;
        }
        if (isHovering || isFocused) {
          return theme.fillColorScheme.contentHover;
        }
        return theme.fillColorScheme.content;
      },
      onTap: onBack,
    );
  }

  Widget buildApplyButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: AFFilledTextButton.primary(
        text: LocaleKeys.settings_appearance_documentSettings_apply.tr(),
        onTap: () => menuState.onApply(widget.onInfoChanged),
      ),
    );
  }

  void onBack() {
    final serviceInfo = context.read<MentionMenuServiceInfo?>();
    if (serviceInfo == null) return;
    serviceInfo.onMenuReplace.call(
      MentionMenuBuilderInfo(
        builder: (service, lrbt) => service.buildMultiBlocProvider(
          (context) => Provider.value(
            value: serviceInfo,
            child: InviteMenu(
              info: widget.info,
              query: widget.query,
              onInfoChanged: (v) => widget.onInfoChanged(v),
            ),
          ),
        ),
        menuSize: Size.square(400),
      ),
    );
  }

  void onDismiss() {
    final mentionInfo = context.read<MentionMenuServiceInfo?>();
    mentionInfo?.onDismiss.call();
  }

  void updateInfo(InviteInfo newInfo) {
    if (mounted) {
      setState(() {
        menuState.info = newInfo;
        final newDetail = newInfo.contactDetail;
        if (newDetail != null) {
          menuState.detail = newDetail;
        }
      });
    }
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

extension ContactDetailMenuStateWidgetExtension on ContactDetailMenuState {
  Widget buildEmailField({ValueChanged<String>? onChanged}) {
    return AFTextField(
      key: emailKey,
      hintText: LocaleKeys.document_mentionMenu_emailInputHint.tr(),
      size: AFTextFieldSize.m,
      focusNode: emailFocusNode,
      controller: emailController,
      onChanged: onChanged,
    );
  }

  Widget buildNameField({ValueChanged<String>? onChanged}) {
    return AFTextField(
      key: nameKey,
      hintText: LocaleKeys.document_mentionMenu_contactInputHint.tr(),
      size: AFTextFieldSize.m,
      focusNode: nameFocusNode,
      controller: nameController,
      onChanged: onChanged,
    );
  }

  Widget buildDescriptionField({ValueChanged<String>? onChanged}) {
    return AFTextField(
      maxLines: null,
      expands: true,
      maxLength: 190,
      textAlignVertical: TextAlignVertical.top,
      size: AFTextFieldSize.m,
      keyboardType: TextInputType.multiline,
      controller: descriptionController,
      hintText: LocaleKeys.document_mentionMenu_aboutContactHint.tr(),
      onChanged: onChanged,
    );
  }

  bool onApply(ValueChanged<InviteInfo> onInfoChanged) {
    if (info.email.isEmpty) {
      emailKey.currentState?.syncError(
        errorText: LocaleKeys.document_mentionMenu_emailInputError.tr(),
      );
      return false;
    }
    if (detail.name.isEmpty) {
      nameKey.currentState?.syncError(
        errorText: LocaleKeys.document_mentionMenu_contactInputError.tr(),
      );
      return false;
    }
    nameKey.currentState?.clearError();
    emailKey.currentState?.clearError();
    onInfoChanged.call(info);
    return true;
  }
}

class ContactDetailMenuState {
  ContactDetailMenuState({
    required this.nameFocusNode,
    required this.emailFocusNode,
    required this.menuFocusNode,
    required this.nameController,
    required this.emailController,
    required this.descriptionController,
    required this.info,
    required this.detail,
  });
  final FocusNode nameFocusNode;
  final FocusNode emailFocusNode;
  final FocusScopeNode menuFocusNode;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController descriptionController;

  InviteInfo info;
  ContactDetail detail;

  final nameKey = GlobalKey<AFTextFieldState>();
  final emailKey = GlobalKey<AFTextFieldState>();

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    descriptionController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    menuFocusNode.dispose();
  }
}
