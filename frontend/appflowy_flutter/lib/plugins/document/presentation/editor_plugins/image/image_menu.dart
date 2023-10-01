import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ImageMenu extends StatefulWidget {
  const ImageMenu({
    super.key,
    required this.node,
    required this.state,
  });

  final Node node;
  final ImageBlockComponentWidgetState state;

  @override
  State<ImageMenu> createState() => _ImageMenuState();
}

class _ImageMenuState extends State<ImageMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          _ImageCopyLinkButton(
            onTap: copyImageLink,
          ),
          const HSpace(4),
          _ImageAlignButton(
            node: widget.node,
            state: widget.state,
          ),
          const _Divider(),
          _ImageDeleteButton(
            onTap: () => deleteImage(),
          ),
          const HSpace(4),
        ],
      ),
    );
  }

  void copyImageLink() {
    final url = widget.node.attributes[ImageBlockKeys.url];
    if (url != null) {
      Clipboard.setData(ClipboardData(text: url));
      showSnackBarMessage(
        context,
        LocaleKeys.document_plugins_image_copiedToPasteBoard.tr(),
      );
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
}

class _ImageCopyLinkButton extends StatelessWidget {
  const _ImageCopyLinkButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const FlowySvg(
        FlowySvgs.copy_s,
        size: Size.square(16),
      ),
    );
  }
}

class _ImageAlignButton extends StatefulWidget {
  const _ImageAlignButton({
    required this.node,
    required this.state,
  });

  final Node node;
  final ImageBlockComponentWidgetState state;

  @override
  State<_ImageAlignButton> createState() => _ImageAlignButtonState();
}

const interceptorKey = 'image-align';

class _ImageAlignButtonState extends State<_ImageAlignButton> {
  final gestureInterceptor = SelectionGestureInterceptor(
    key: interceptorKey,
    canTap: (details) => false,
  );

  String get align => widget.node.attributes['align'] ?? 'center';
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
        child: buildAlignIcon(),
        popupBuilder: (_) {
          preventMenuClose();
          return _AlignButtons(
            onAlignChanged: onAlignChanged,
          );
        },
      ),
    );
  }

  void onAlignChanged(String align) {
    popoverController.close();

    final transaction = editorState.transaction;
    transaction.updateNode(widget.node, {
      ImageBlockKeys.align: align,
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
      case 'right':
        return FlowySvgs.align_right_s;
      case 'center':
        return FlowySvgs.align_center_s;
      case 'left':
      default:
        return FlowySvgs.align_left_s;
    }
  }

  Widget buildAlignIcon() {
    return FlowySvg(
      iconFor(align),
      size: const Size.square(16),
    );
  }
}

class _AlignButtons extends StatelessWidget {
  const _AlignButtons({
    required this.onAlignChanged,
  });

  final Function(String align) onAlignChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(4),
          _AlignButton(
            icon: FlowySvgs.align_left_s,
            onTap: () => onAlignChanged('left'),
          ),
          const _Divider(),
          _AlignButton(
            icon: FlowySvgs.align_center_s,
            onTap: () => onAlignChanged('center'),
          ),
          const _Divider(),
          _AlignButton(
            icon: FlowySvgs.align_right_s,
            onTap: () => onAlignChanged('right'),
          ),
          const HSpace(4),
        ],
      ),
    );
  }
}

class _AlignButton extends StatelessWidget {
  const _AlignButton({
    required this.icon,
    required this.onTap,
  });

  final FlowySvgData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FlowySvg(
        icon,
        size: const Size.square(16),
      ),
    );
  }
}

class _ImageDeleteButton extends StatelessWidget {
  const _ImageDeleteButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const FlowySvg(
        FlowySvgs.delete_s,
        size: Size.square(16),
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
      child: Container(
        width: 1,
        color: Colors.grey,
      ),
    );
  }
}
