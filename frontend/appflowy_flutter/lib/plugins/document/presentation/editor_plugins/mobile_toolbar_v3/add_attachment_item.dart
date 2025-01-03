import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/permission/permission_checker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

@visibleForTesting
const addAttachmentToolbarItemKey = ValueKey('add_attachment_toolbar_item');

final addAttachmentItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, service, _, onAction) {
    return AppFlowyMobileToolbarIconItem(
      key: addAttachmentToolbarItemKey,
      editorState: editorState,
      icon: FlowySvgs.media_s,
      onTap: () {
        final documentId = context.read<DocumentBloc>().documentId;
        final isLocalMode = context.read<DocumentBloc>().isLocalMode;

        final selection = editorState.selection;
        service.closeKeyboard();

        // delay to wait the keyboard closed.
        Future.delayed(const Duration(milliseconds: 100), () async {
          unawaited(
            editorState.updateSelectionWithReason(
              selection,
              extraInfo: {
                selectionExtraInfoDisableMobileToolbarKey: true,
                selectionExtraInfoDisableFloatingToolbar: true,
                selectionExtraInfoDoNotAttachTextService: true,
              },
            ),
          );

          keepEditorFocusNotifier.increase();
          final didAddAttachment = await showAddAttachmentMenu(
            AppGlobals.rootNavKey.currentContext!,
            documentId: documentId,
            isLocalMode: isLocalMode,
            editorState: editorState,
            selection: selection!,
          );

          if (didAddAttachment != true) {
            unawaited(editorState.updateSelectionWithReason(selection));
          }
        });
      },
    );
  },
);

Future<bool?> showAddAttachmentMenu(
  BuildContext context, {
  required String documentId,
  required bool isLocalMode,
  required EditorState editorState,
  required Selection selection,
}) async =>
    showMobileBottomSheet<bool>(
      context,
      showDragHandle: true,
      barrierColor: Colors.transparent,
      backgroundColor:
          ToolbarColorExtension.of(context).toolbarMenuBackgroundColor,
      elevation: 20,
      isScrollControlled: false,
      enableDraggableScrollable: true,
      builder: (_) => _AddAttachmentMenu(
        documentId: documentId,
        isLocalMode: isLocalMode,
        editorState: editorState,
        selection: selection,
      ),
    );

class _AddAttachmentMenu extends StatelessWidget {
  const _AddAttachmentMenu({
    required this.documentId,
    required this.isLocalMode,
    required this.editorState,
    required this.selection,
  });

  final String documentId;
  final bool isLocalMode;
  final EditorState editorState;
  final Selection selection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileQuickActionButton(
            text: LocaleKeys.document_attachmentMenu_choosePhoto.tr(),
            icon: FlowySvgs.image_rounded_s,
            iconSize: const Size.square(20),
            onTap: () async => selectPhoto(context),
          ),
          const MobileQuickActionDivider(),
          MobileQuickActionButton(
            text: LocaleKeys.document_attachmentMenu_takePicture.tr(),
            icon: FlowySvgs.camera_s,
            iconSize: const Size.square(20),
            onTap: () async => selectCamera(context),
          ),
          const MobileQuickActionDivider(),
          MobileQuickActionButton(
            text: LocaleKeys.document_attachmentMenu_chooseFile.tr(),
            icon: FlowySvgs.file_s,
            iconSize: const Size.square(20),
            onTap: () async => selectFile(context),
          ),
        ],
      ),
    );
  }

  Future<void> _insertNode(Node node) async {
    Future.delayed(
      const Duration(milliseconds: 100),
      () async {
        // if current selected block is a empty paragraph block, replace it with the new block.
        if (selection.isCollapsed) {
          final path = selection.end.path;
          final currentNode = editorState.getNodeAtPath(path);
          final text = currentNode?.delta?.toPlainText();
          if (currentNode != null &&
              currentNode.type == ParagraphBlockKeys.type &&
              text != null &&
              text.isEmpty) {
            final transaction = editorState.transaction;
            transaction.insertNode(path.next, node);
            transaction.deleteNode(currentNode);
            transaction.afterSelection =
                Selection.collapsed(Position(path: path));
            transaction.selectionExtraInfo = {};
            return editorState.apply(transaction);
          }
        }

        await editorState.insertBlockAfterCurrentSelection(selection, node);
      },
    );
  }

  Future<void> insertImage(BuildContext context, XFile image) async {
    CustomImageType type = CustomImageType.local;
    String? path;
    if (isLocalMode) {
      path = await saveImageToLocalStorage(image.path);
    } else {
      (path, _) = await saveImageToCloudStorage(image.path, documentId);
      type = CustomImageType.internal;
    }

    if (path != null) {
      final node = customImageNode(url: path, type: type);
      await _insertNode(node);
    }
  }

  Future<void> selectPhoto(BuildContext context) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      await insertImage(context, image);
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> selectCamera(BuildContext context) async {
    final cameraPermission =
        await PermissionChecker.checkCameraPermission(context);
    if (!cameraPermission) {
      Log.error('Has no permission to access the camera');
      return;
    }

    final image = await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null && context.mounted) {
      await insertImage(context, image);
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> selectFile(BuildContext context) async {
    final result = await getIt<FilePickerService>().pickFiles();
    final file = result?.files.first.xFile;
    if (file != null) {
      FileUrlType type = FileUrlType.local;
      String? path;
      if (isLocalMode) {
        path = await saveFileToLocalStorage(file.path);
      } else {
        (path, _) = await saveFileToCloudStorage(file.path, documentId);
        type = FileUrlType.cloud;
      }

      if (path != null) {
        final node = fileNode(url: path, type: type, name: file.name);
        await _insertNode(node);
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
