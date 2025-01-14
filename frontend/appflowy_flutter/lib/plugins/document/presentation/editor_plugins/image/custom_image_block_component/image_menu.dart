import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/resizeable_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ImageMenu extends StatefulWidget {
  const ImageMenu({
    super.key,
    required this.node,
    required this.state,
    required this.imageStateNotifier,
  });

  final Node node;
  final CustomImageBlockComponentState state;
  final ValueNotifier<ResizableImageState> imageStateNotifier;

  @override
  State<ImageMenu> createState() => _ImageMenuState();
}

class _ImageMenuState extends State<ImageMenu> {
  late final String? url = widget.node.attributes[CustomImageBlockKeys.url];

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = url == null || url!.isEmpty;
    final theme = Theme.of(context);
    return ValueListenableBuilder<ResizableImageState>(
      valueListenable: widget.imageStateNotifier,
      builder: (_, state, child) {
        if (state == ResizableImageState.loading && !isPlaceholder) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 32,
          decoration: BoxDecoration(
            color: theme.cardColor,
            boxShadow: [
              BoxShadow(
                blurRadius: 5,
                spreadRadius: 1,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Row(
            children: [
              const HSpace(4),
              if (!isPlaceholder) ...[
                MenuBlockButton(
                  tooltip: LocaleKeys.document_imageBlock_openFullScreen.tr(),
                  iconData: FlowySvgs.full_view_s,
                  onTap: openFullScreen,
                ),
                const HSpace(4),
                MenuBlockButton(
                  tooltip: LocaleKeys.editor_copy.tr(),
                  iconData: FlowySvgs.copy_s,
                  onTap: copyImageLink,
                ),
                const HSpace(4),
              ],
              if (widget.state.editorState.editable) ...[
                if (!isPlaceholder) ...[
                  _ImageAlignButton(node: widget.node, state: widget.state),
                  const _Divider(),
                ],
                MenuBlockButton(
                  tooltip: LocaleKeys.button_delete.tr(),
                  iconData: FlowySvgs.trash_s,
                  onTap: deleteImage,
                ),
                const HSpace(4),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> copyImageLink() async {
    if (url != null) {
      // paste the image url and the image data
      final imageData = await captureImage();

      try {
        // /image
        await getIt<ClipboardService>().setData(
          ClipboardServiceData(
            plainText: url!,
            image: ('png', imageData),
          ),
        );

        if (mounted) {
          showToastNotification(
            context,
            message: LocaleKeys.message_copy_success.tr(),
          );
        }
      } catch (e) {
        if (mounted) {
          showToastNotification(
            context,
            message: LocaleKeys.message_copy_fail.tr(),
            type: ToastificationType.error,
          );
        }
      }
    }
  }

  Future<void> deleteImage() async {
    final node = widget.node;
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.afterSelection = null;
    await editorState.apply(transaction);
  }

  void openFullScreen() {
    showDialog(
      context: context,
      builder: (_) => InteractiveImageViewer(
        userProfile: context.read<UserWorkspaceBloc>().userProfile,
        imageProvider: AFBlockImageProvider(
          images: [
            ImageBlockData(
              url: url!,
              type: CustomImageType.fromIntValue(
                widget.node.attributes[CustomImageBlockKeys.imageType] ?? 2,
              ),
            ),
          ],
          onDeleteImage: widget.state.editorState.editable
              ? (_) async {
                  final transaction = widget.state.editorState.transaction;
                  transaction.deleteNode(widget.node);
                  await widget.state.editorState.apply(transaction);
                }
              : null,
        ),
      ),
    );
  }

  Future<Uint8List> captureImage() async {
    final boundary = widget.state.imageKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    final image = await boundary?.toImage();
    final byteData = await image?.toByteData(format: ImageByteFormat.png);
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
  }
}

class _ImageAlignButton extends StatefulWidget {
  const _ImageAlignButton({required this.node, required this.state});

  final Node node;
  final CustomImageBlockComponentState state;

  @override
  State<_ImageAlignButton> createState() => _ImageAlignButtonState();
}

const _interceptorKey = 'image-align';

class _ImageAlignButtonState extends State<_ImageAlignButton> {
  final gestureInterceptor = SelectionGestureInterceptor(
    key: _interceptorKey,
    canTap: (details) => false,
  );

  String get align =>
      widget.node.attributes[CustomImageBlockKeys.align] ?? centerAlignmentKey;
  final popoverController = PopoverController();
  late final EditorState editorState;

  @override
  void initState() {
    super.initState();
    editorState = context.read<EditorState>();
  }

  @override
  void dispose() {
    allowMenuClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnoreParentGestureWidget(
      child: AppFlowyPopover(
        onClose: allowMenuClose,
        controller: popoverController,
        windowPadding: const EdgeInsets.all(0),
        margin: const EdgeInsets.all(0),
        direction: PopoverDirection.bottomWithCenterAligned,
        offset: const Offset(0, 10),
        child: MenuBlockButton(
          tooltip: LocaleKeys.document_plugins_optionAction_align.tr(),
          iconData: iconFor(align),
        ),
        popupBuilder: (_) {
          preventMenuClose();
          return _AlignButtons(onAlignChanged: onAlignChanged);
        },
      ),
    );
  }

  void onAlignChanged(String align) {
    popoverController.close();

    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {CustomImageBlockKeys.align: align});
    editorState.apply(transaction);

    allowMenuClose();
  }

  void preventMenuClose() {
    widget.state.alwaysShowMenu = true;
    editorState.service.selectionService.registerGestureInterceptor(
      gestureInterceptor,
    );
  }

  void allowMenuClose() {
    widget.state.alwaysShowMenu = false;
    editorState.service.selectionService.unregisterGestureInterceptor(
      _interceptorKey,
    );
  }

  FlowySvgData iconFor(String alignment) {
    switch (alignment) {
      case rightAlignmentKey:
        return FlowySvgs.align_right_s;
      case centerAlignmentKey:
        return FlowySvgs.align_center_s;
      case leftAlignmentKey:
      default:
        return FlowySvgs.align_left_s;
    }
  }
}

class _AlignButtons extends StatelessWidget {
  const _AlignButtons({required this.onAlignChanged});

  final Function(String align) onAlignChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(4),
          MenuBlockButton(
            tooltip: LocaleKeys.document_plugins_optionAction_left,
            iconData: FlowySvgs.align_left_s,
            onTap: () => onAlignChanged(leftAlignmentKey),
          ),
          const _Divider(),
          MenuBlockButton(
            tooltip: LocaleKeys.document_plugins_optionAction_center,
            iconData: FlowySvgs.align_center_s,
            onTap: () => onAlignChanged(centerAlignmentKey),
          ),
          const _Divider(),
          MenuBlockButton(
            tooltip: LocaleKeys.document_plugins_optionAction_right,
            iconData: FlowySvgs.align_right_s,
            onTap: () => onAlignChanged(rightAlignmentKey),
          ),
          const HSpace(4),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(width: 1, color: Colors.grey),
    );
  }
}
