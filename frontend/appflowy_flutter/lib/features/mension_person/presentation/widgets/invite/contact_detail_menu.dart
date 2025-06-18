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
    required this.onInfoChanged,
  });

  final InviteInfo info;
  final ValueChanged<InviteInfo> onInfoChanged;

  @override
  State<ContactDetailMenu> createState() => _ContactDetailMenuState();
}

class _ContactDetailMenuState extends State<ContactDetailMenu> {
  late final FocusNode nameFocusNode = FocusNode(onKeyEvent: onFocusKeyEvent);
  late final FocusScopeNode menuFocusNode =
      FocusScopeNode(onKeyEvent: onFocusKeyEvent);
  late final TextEditingController nameController =
      TextEditingController(text: info.email);
  late final TextEditingController descriptionController =
      TextEditingController(text: detail.description);

  late InviteInfo info = widget.info;
  late ContactDetail detail =
      info.contactDetail ?? ContactDetail(name: info.email);
  final nameKey = GlobalKey<AFTextFieldState>();

  @override
  void initState() {
    super.initState();
    nameFocusNode.makeSureHasFocus(() => !mounted);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    nameFocusNode.dispose();
    menuFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context), spacing = theme.spacing;
    return FocusScope(
      node: menuFocusNode,
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
                  buildTitle(context),
                  VSpace(spacing.l),
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

  Widget buildTitle(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      LocaleKeys.document_mentionMenu_contactDetail.tr(),
      style: theme.textStyle.heading4.prominent(
        color: theme.textColorScheme.primary,
      ),
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

  Widget buildNameField() {
    return SizedBox(
      width: 360,
      child: AFTextField(
        key: nameKey,
        hintText: LocaleKeys.document_mentionMenu_contactInputHint.tr(),
        size: AFTextFieldSize.m,
        focusNode: nameFocusNode,
        controller: nameController,
        onChanged: (text) {
          detail = detail.copyWith(name: text);
          updateInfo(info.copyWith(contactDetail: () => detail));
        },
      ),
    );
  }

  Widget buildDescriptionField() {
    return SizedBox(
      width: 360,
      height: 68,
      child: AFTextField(
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        size: AFTextFieldSize.m,
        keyboardType: TextInputType.multiline,
        controller: descriptionController,
        hintText: LocaleKeys.document_mentionMenu_aboutContactHint.tr(),
        onChanged: (text) {
          detail = detail.copyWith(description: text);
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
        onTap: onApply,
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
              onInfoChanged: (v) => widget.onInfoChanged(v),
            ),
          ),
        ),
        menuSize: Size.square(400),
      ),
    );
  }

  void onApply() {
    if (detail.name.isEmpty) {
      nameKey.currentState?.syncError(
        errorText: LocaleKeys.document_mentionMenu_contactInputError.tr(),
      );
      return;
    }
    nameKey.currentState?.clearError();
    widget.onInfoChanged.call(info);
  }

  void onDismiss() {
    final mentionInfo = context.read<MentionMenuServiceInfo?>();
    mentionInfo?.onDismiss.call();
  }

  void updateInfo(InviteInfo newInfo) {
    if (mounted) {
      setState(() {
        info = newInfo;
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
