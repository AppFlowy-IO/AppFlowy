import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/align_toolbar_item/align_toolbar_item.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:provider/provider.dart';

class VideoMenu extends StatefulWidget {
  const VideoMenu({
    super.key,
    required this.node,
    required this.state,
  });

  final Node node;
  final VideoBlockComponentState state;

  @override
  State<VideoMenu> createState() => _VideoMenuState();
}

class _VideoMenuState extends State<VideoMenu> {
  late final String? url = widget.node.attributes[VideoBlockKeys.url];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(4.0),
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          const HSpace(4),
          MenuBlockButton(
            tooltip: LocaleKeys.editor_copyLink.tr(),
            iconData: FlowySvgs.copy_s,
            onTap: copyVideoLink,
          ),
          const HSpace(4),
          _VideoAlignButton(
            node: widget.node,
            state: widget.state,
          ),
          const _Divider(),
          MenuBlockButton(
            tooltip: LocaleKeys.button_delete.tr(),
            iconData: FlowySvgs.delete_s,
            onTap: deleteVideo,
          ),
          const HSpace(4),
        ],
      ),
    );
  }

  void copyVideoLink() {
    if (url != null) {
      Clipboard.setData(ClipboardData(text: url!));
      showSnackBarMessage(
        context,
        LocaleKeys.document_plugins_video_copiedToPasteBoard.tr(),
      );
    }
  }

  Future<void> deleteVideo() async {
    final node = widget.node;
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.afterSelection = null;
    await editorState.apply(transaction);
  }
}

class _VideoAlignButton extends StatefulWidget {
  const _VideoAlignButton({
    required this.node,
    required this.state,
  });

  final Node node;
  final VideoBlockComponentState state;

  @override
  State<_VideoAlignButton> createState() => _VideoAlignButtonState();
}

const interceptorKey = 'video-align';

class _VideoAlignButtonState extends State<_VideoAlignButton> {
  final gestureInterceptor = SelectionGestureInterceptor(
    key: interceptorKey,
    canTap: (_) => false,
  );

  String get align =>
      widget.node.attributes[VideoBlockKeys.alignment] ?? centerAlignmentKey;
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
    transaction.updateNode(widget.node, {
      VideoBlockKeys.alignment: align,
    });
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
      interceptorKey,
    );
  }

  FlowySvgData iconFor(String alignment) {
    switch (alignment) {
      case leftAlignmentKey:
        return FlowySvgs.align_left_s;
      case rightAlignmentKey:
        return FlowySvgs.align_right_s;
      case centerAlignmentKey:
      default:
        return FlowySvgs.align_center_s;
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
