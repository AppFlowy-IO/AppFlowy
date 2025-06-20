import 'package:appflowy/features/mension_person/data/models/invite.dart';
import 'package:appflowy/features/mension_person/presentation/menu_extension.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/invite/contact_detail_menu.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

void showMobileContactDetailMenu({
  required BuildContext context,
  required InviteInfo info,
  required ValueChanged<InviteInfo> onInfoChanged,
}) {
  final theme = AppFlowyTheme.of(context);
  showMobileBottomSheet(
    context,
    dragHandleBuilder: (_) => VSpace(20),
    showDragHandle: true,
    showDivider: false,
    isDragEnabled: false,
    enableDraggableScrollable: true,
    initialChildSize: 0.9,
    minChildSize: 0.9,
    maxChildSize: 0.9,
    backgroundColor: theme.surfaceColorScheme.primary,
    builder: (_) => MobileContactDetailMenu(
      info: info,
      onInfoChanged: onInfoChanged,
    ),
  );
}

class MobileContactDetailMenu extends StatefulWidget {
  const MobileContactDetailMenu({
    super.key,
    required this.info,
    required this.onInfoChanged,
  });

  final InviteInfo info;
  final ValueChanged<InviteInfo> onInfoChanged;

  @override
  State<MobileContactDetailMenu> createState() =>
      _MobileContactDetailMenuState();
}

class _MobileContactDetailMenuState extends State<MobileContactDetailMenu> {
  late final ContactDetailMenuState menuState = ContactDetailMenuState(
    nameFocusNode: FocusNode(),
    emailFocusNode: FocusNode(),
    menuFocusNode: FocusScopeNode(),
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
              VSpace(spacing.xs),
              buildEmailField(),
              buildSubtitle(LocaleKeys.document_mentionMenu_name.tr()),
              VSpace(spacing.m),
              buildNameField(),
              VSpace(spacing.xl),
              buildSubtitle(LocaleKeys.document_mentionMenu_aboutContact.tr()),
              VSpace(spacing.m),
              buildDescriptionField(),
              VSpace(124),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildHeader() {
    return BottomSheetHeader(
      showBackButton: true,
      showDoneButton: true,
      showCloseButton: false,
      showRemoveButton: false,
      title: LocaleKeys.document_mentionMenu_contactDetail.tr(),
      doneButtonBuilder: (context) {
        final theme = AppFlowyTheme.of(context);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onApply,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.xl,
              vertical: theme.spacing.xs,
            ),
            child: Text(
              LocaleKeys.button_add.tr(),
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
      style: theme.textStyle.caption
          .enhanced(color: theme.textColorScheme.secondary),
    );
  }

  Widget buildEmailField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: menuState.buildEmailField(
        onChanged: (text) => updateInfo(info.copyWith(email: text)),
      ),
    );
  }

  Widget buildNameField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
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
      width: MediaQuery.of(context).size.width,
      height: 132,
      child: menuState.buildDescriptionField(
        onChanged: (text) {
          final detail = menuState.detail.copyWith(description: text);
          updateInfo(info.copyWith(contactDetail: () => detail));
        },
      ),
    );
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

  void onApply() {
    final result = menuState.onApply(widget.onInfoChanged);
    if (result) Navigator.pop(context);
  }
}
