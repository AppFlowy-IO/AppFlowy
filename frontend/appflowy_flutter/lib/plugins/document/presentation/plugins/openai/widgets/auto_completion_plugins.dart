import 'package:appflowy/plugins/document/presentation/plugins/openai/widgets/auto_completion_node_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

SelectionMenuItem autoGeneratorMenuItem = SelectionMenuItem.node(
  name: LocaleKeys.document_plugins_autoGeneratorMenuItemName.tr(),
  iconData: Icons.generating_tokens,
  keywords: ['ai', 'openai' 'writer', 'autogenerator'],
  nodeBuilder: (editorState) {
    final node = Node(
      type: kAutoCompletionInputType,
      attributes: {
        kAutoCompletionInputString: '',
      },
    );
    return node;
  },
  replace: (_, textNode) => textNode.toPlainText().isEmpty,
  updateSelection: null,
);
