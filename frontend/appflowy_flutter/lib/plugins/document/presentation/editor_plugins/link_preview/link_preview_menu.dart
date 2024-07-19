import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/block_menu/block_menu_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/shared.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:provider/provider.dart';

import '../image/custom_image_block_component.dart';

class LinkPreviewMenu extends StatefulWidget {
  const LinkPreviewMenu({
    super.key,
    required this.node,
    required this.state,
  });

  final Node node;
  final LinkPreviewBlockComponentState state;

  @override
  State<LinkPreviewMenu> createState() => _LinkPreviewMenuState();
}

class _LinkPreviewMenuState extends State<LinkPreviewMenu> {
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
          MenuBlockButton(
            tooltip: LocaleKeys.document_plugins_urlPreview_convertToLink.tr(),
            iconData: FlowySvgs.m_aa_link_s,
            onTap: () => convertUrlPreviewNodeToLink(
              context.read<EditorState>(),
              widget.node,
            ),
          ),
          const HSpace(4),
          MenuBlockButton(
            tooltip: LocaleKeys.editor_copyLink.tr(),
            iconData: FlowySvgs.copy_s,
            onTap: copyImageLink,
          ),
          const _Divider(),
          MenuBlockButton(
            tooltip: LocaleKeys.button_delete.tr(),
            iconData: FlowySvgs.delete_s,
            onTap: deleteLinkPreviewNode,
          ),
          const HSpace(4),
        ],
      ),
    );
  }

  void copyImageLink() {
    final url = widget.node.attributes[CustomImageBlockKeys.url];
    if (url != null) {
      Clipboard.setData(ClipboardData(text: url));
      showSnackBarMessage(
        context,
        LocaleKeys.document_plugins_urlPreview_copiedToPasteBoard.tr(),
      );
    }
  }

  Future<void> deleteLinkPreviewNode() async {
    final node = widget.node;
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    transaction.deleteNode(node);
    transaction.afterSelection = null;
    await editorState.apply(transaction);
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
