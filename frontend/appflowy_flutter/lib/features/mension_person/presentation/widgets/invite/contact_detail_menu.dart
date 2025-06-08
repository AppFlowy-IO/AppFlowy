import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'invite_menu.dart';

class ContactDetail {
  ContactDetail({
    this.name = '',
    this.description = '',
  });

  final String name;
  final String description;

  ContactDetail copyWith({
    String? name,
    String? description,
  }) {
    return ContactDetail(
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

class ContactDetailMenu extends StatefulWidget {
  const ContactDetailMenu({
    super.key,
    required this.info,
    required this.onInfoChanged,
  });

  final InviteMenuInfo info;
  final ValueChanged<InviteMenuInfo> onInfoChanged;

  @override
  State<ContactDetailMenu> createState() => _ContactDetailMenuState();
}

class _ContactDetailMenuState extends State<ContactDetailMenu> {
  late FocusNode nameFocusNode = FocusNode();
  late FocusNode menuFocusNode = FocusNode();
  late TextEditingController nameController =
      TextEditingController(text: info.email);
  late TextEditingController descriptionController =
      TextEditingController(text: detail.description);

  late InviteMenuInfo info = widget.info;

  late ContactDetail detail = info.contactDetail ?? ContactDetail();

  @override
  void initState() {
    super.initState();
    makeSureHasFocus();
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
    return GestureDetector(
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
                buildSubtitle(
                  context,
                  LocaleKeys.document_mentionMenu_name.tr(),
                ),
                VSpace(spacing.xs),
                buildNameField(),
                VSpace(spacing.xxl),
                buildSubtitle(
                  context,
                  LocaleKeys.document_mentionMenu_aboutContact.tr(),
                ),
                VSpace(spacing.xs),
                buildDescriptionField(),
                VSpace(spacing.xxl),
                buildApplyButton(),
              ],
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

  Widget buildSubtitle(BuildContext context, String title) {
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

  Widget buildApplyButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: AFFilledTextButton.primary(
        text: LocaleKeys.settings_appearance_documentSettings_apply.tr(),
        onTap: () {
          if (detail.name.isEmpty) {
            showToastNotification(
              /// TODO: replace with formal text
              message: 'Name can not be empty',
              type: ToastificationType.error,
            );
            return;
          }
          if (detail.description.isEmpty) {
            showToastNotification(
              /// TODO: replace with formal text
              message: 'Description can not be empty',
              type: ToastificationType.error,
            );
            return;
          }
          widget.onInfoChanged.call(info);
        },
      ),
    );
  }

  void updateInfo(InviteMenuInfo newInfo) {
    if (mounted) {
      setState(() {
        info = newInfo;
      });
    }
  }

  Future<void> makeSureHasFocus() async {
    final focusNode = nameFocusNode;
    if (!mounted || focusNode.hasFocus) return;
    focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      makeSureHasFocus();
    });
  }
}
