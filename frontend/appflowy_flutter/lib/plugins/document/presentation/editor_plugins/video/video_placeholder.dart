import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/video/upload_video_menu.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log, UploadImageMenu;
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

class VideoPlaceholder extends StatefulWidget {
  const VideoPlaceholder({super.key, required this.node});

  final Node node;

  @override
  State<VideoPlaceholder> createState() => VideoPlaceholderState();
}

class VideoPlaceholderState extends State<VideoPlaceholder> {
  final controller = PopoverController();
  final documentService = DocumentService();
  late final editorState = context.read<EditorState>();

  bool showLoading = false;

  @override
  Widget build(BuildContext context) {
    final Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyHover(
        style: HoverStyle(borderRadius: BorderRadius.circular(4)),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const HSpace(10),
              const Icon(Icons.featured_video_outlined, size: 24),
              const HSpace(10),
              FlowyText(LocaleKeys.document_plugins_video_emptyLabel.tr()),
            ],
          ),
        ),
      ),
    );

    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        controller: controller,
        direction: PopoverDirection.bottomWithCenterAligned,
        constraints: const BoxConstraints(
          maxWidth: 540,
          maxHeight: 360,
          minHeight: 80,
        ),
        clickHandler: PopoverClickHandler.gestureDetector,
        popupBuilder: (_) => UploadVideoMenu(
          onUrlSubmitted: (url) {
            controller.close();
            WidgetsBinding.instance.addPostFrameCallback(
              (_) async => updateSrc(url),
            );
          },
        ),
        child: child,
      );
    } else {
      return MobileBlockActionButtons(
        node: widget.node,
        editorState: editorState,
        child: GestureDetector(
          onTap: () {
            editorState.updateSelectionWithReason(null, extraInfo: {});
            showUploadVideoMenu();
          },
          child: child,
        ),
      );
    }
  }

  void showUploadVideoMenu() {
    if (PlatformExtension.isDesktopOrWeb) {
      controller.show();
    } else {
      showMobileBottomSheet(
        context,
        title: LocaleKeys.editor_image.tr(),
        showHeader: true,
        showCloseButton: true,
        showDragHandle: true,
        builder: (context) => Container(
          margin: const EdgeInsets.only(top: 12.0),
          constraints: const BoxConstraints(
            maxHeight: 340,
            minHeight: 80,
          ),
          child: UploadVideoMenu(
            onUrlSubmitted: (url) async {
              context.pop();
              await updateSrc(url);
            },
          ),
        ),
      );
    }
  }

  Future<void> updateSrc(String url) async {
    if (url.isEmpty || !isURL(url)) {
      // show error
      showSnackBarMessage(
        context,
        LocaleKeys.document_imageBlock_error_invalidImage.tr(),
      );
      return;
    }

    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      VideoBlockKeys.url: url,
    });
    await editorState.apply(transaction);
  }
}
