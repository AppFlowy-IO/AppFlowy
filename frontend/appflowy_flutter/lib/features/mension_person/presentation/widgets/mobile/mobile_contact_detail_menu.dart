import 'package:appflowy/features/mension_person/data/models/invite.dart';
import 'package:appflowy/features/mension_person/presentation/menu_extension.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
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
    dragHandleBuilder: (_) => const DragHandleV2(),
    showDragHandle: true,
    showDivider: false,
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
  late InviteInfo info = widget.info;

  late ContactDetail detail =
      info.contactDetail ?? ContactDetail(name: info.email);
  final nameKey = GlobalKey<AFTextFieldState>();
  late FocusNode nameFocusNode = FocusNode();
  late TextEditingController nameController =
      TextEditingController(text: info.email);
  late TextEditingController descriptionController =
      TextEditingController(text: detail.description);

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
              buildSubtitle(LocaleKeys.document_mentionMenu_name.tr()),
              VSpace(spacing.m),
              buildNameField(),
              VSpace(spacing.xl),
              buildSubtitle(LocaleKeys.document_mentionMenu_aboutContact.tr()),
              VSpace(spacing.m),
              buildDescriptionField(),
              VSpace(80),
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
            padding: EdgeInsets.only(right: theme.spacing.xl),
            child: Text(
              LocaleKeys.document_mentionMenu_invite.tr(),
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

  Widget buildNameField() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
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
      width: MediaQuery.of(context).size.width,
      height: 132,
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

  void updateInfo(InviteInfo newInfo) {
    if (mounted) {
      setState(() {
        info = newInfo;
      });
    }
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
    Navigator.pop(context);
  }
}
