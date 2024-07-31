import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileBlockMenu extends StatefulWidget {
  const FileBlockMenu({
    super.key,
    required this.controller,
    required this.node,
    required this.editorState,
  });

  final PopoverController controller;
  final Node node;
  final EditorState editorState;

  @override
  State<FileBlockMenu> createState() => _FileBlockMenuState();
}

class _FileBlockMenuState extends State<FileBlockMenu> {
  final nameController = TextEditingController();
  final errorMessage = ValueNotifier<String?>(null);
  BuildContext? renameContext;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.node.attributes[FileBlockKeys.name] ?? '';
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nameController.text.length,
    );
  }

  @override
  void dispose() {
    errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadedAtInMS =
        widget.node.attributes[FileBlockKeys.uploadedAt] as int?;
    final uploadedAt = uploadedAtInMS != null
        ? DateTime.fromMillisecondsSinceEpoch(uploadedAtInMS)
        : null;
    final dateFormat = context.read<AppearanceSettingsCubit>().state.dateFormat;
    final urlType =
        FileUrlType.fromIntValue(widget.node.attributes[FileBlockKeys.urlType]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        HoverButton(
          itemHeight: 20,
          leftIcon: const FlowySvg(FlowySvgs.edit_s),
          name: LocaleKeys.document_plugins_file_renameFile_title.tr(),
          onTap: () {
            widget.controller.close();
            showCustomConfirmDialog(
              context: context,
              title: LocaleKeys.document_plugins_file_renameFile_title.tr(),
              description:
                  LocaleKeys.document_plugins_file_renameFile_description.tr(),
              closeOnConfirm: false,
              builder: (context) {
                renameContext = context;

                return _RenameTextField(
                  nameController: nameController,
                  errorMessage: errorMessage,
                  onSubmitted: _saveName,
                );
              },
              confirmLabel: LocaleKeys.button_save.tr(),
              onConfirm: _saveName,
            );
          },
        ),
        const VSpace(4),
        HoverButton(
          itemHeight: 20,
          leftIcon: const FlowySvg(FlowySvgs.delete_s),
          name: LocaleKeys.button_delete.tr(),
          onTap: () {
            final transaction = widget.editorState.transaction
              ..deleteNode(widget.node);
            widget.editorState.apply(transaction);
            widget.controller.close();
          },
        ),
        if (uploadedAt != null) ...[
          const Divider(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FlowyText.regular(
              [FileUrlType.cloud, FileUrlType.local].contains(urlType)
                  ? LocaleKeys.document_plugins_file_uploadedAt.tr(
                      args: [dateFormat.formatDate(uploadedAt, false)],
                    )
                  : LocaleKeys.document_plugins_file_linkedAt.tr(
                      args: [dateFormat.formatDate(uploadedAt, false)],
                    ),
              fontSize: 14,
              maxLines: 2,
              color: Theme.of(context).hintColor,
            ),
          ),
          const VSpace(2),
        ],
      ],
    );
  }

  void _saveName() {
    if (nameController.text.isEmpty) {
      errorMessage.value =
          LocaleKeys.document_plugins_file_renameFile_nameEmptyError.tr();
      return;
    }

    final attributes = widget.node.attributes;
    attributes[FileBlockKeys.name] = nameController.text;

    final transaction = widget.editorState.transaction
      ..updateNode(widget.node, attributes);
    widget.editorState.apply(transaction);

    if (renameContext != null) {
      Navigator.of(renameContext!).pop();
    }
  }
}

class _RenameTextField extends StatefulWidget {
  const _RenameTextField({
    required this.nameController,
    required this.errorMessage,
    required this.onSubmitted,
  });

  final TextEditingController nameController;
  final ValueNotifier<String?> errorMessage;
  final VoidCallback onSubmitted;

  @override
  State<_RenameTextField> createState() => _RenameTextFieldState();
}

class _RenameTextFieldState extends State<_RenameTextField> {
  @override
  void initState() {
    super.initState();
    widget.errorMessage.addListener(_setState);
  }

  @override
  void dispose() {
    widget.errorMessage.removeListener(_setState);
    widget.nameController.dispose();
    super.dispose();
  }

  void _setState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyTextField(
          controller: widget.nameController,
          onSubmitted: (_) => widget.onSubmitted(),
        ),
        if (widget.errorMessage.value != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FlowyText(
              widget.errorMessage.value!,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}
