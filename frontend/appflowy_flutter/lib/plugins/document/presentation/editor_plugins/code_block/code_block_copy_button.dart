import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/code_block/code_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

const codeBlockWrapButtonKey = ValueKey('code_block_wrap_button');

CodeBlockCopyBuilder codeBlockCopyBuilder = (editorState, node) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (UniversalPlatform.isDesktopOrWeb)
        _WrapCodeButton(
          editorState: editorState,
          node: node,
        ),
      _CopyButton(node: node),
    ],
  );
};

class _WrapCodeButton extends StatelessWidget {
  const _WrapCodeButton({
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    final isWrapped = node.codeBlockWrapLines;
    final colorScheme = Theme.of(context).colorScheme;
    final tooltip = LocaleKeys.document_codeBlock_wrapTooltip.tr();

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Semantics(
        label: tooltip,
        button: true,
        toggled: isWrapped,
        child: FlowyIconButton(
          key: codeBlockWrapButtonKey,
          tooltipText: tooltip,
          isSelected: isWrapped,
          fillColor:
              isWrapped ? colorScheme.secondaryContainer : Colors.transparent,
          hoverColor: colorScheme.secondaryContainer,
          onPressed: () async {
            final transaction = editorState.transaction
              ..updateNode(
                node,
                {AppFlowyCodeBlockKeys.wrapLines: !isWrapped},
              );
            await editorState.apply(transaction);
          },
          icon: Icon(
            Icons.wrap_text_rounded,
            color: isWrapped
                ? colorScheme.primary
                : AFThemeExtension.of(context).textColor,
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.node});

  final Node node;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FlowyTooltip(
        message: LocaleKeys.document_codeBlock_copyTooltip.tr(),
        child: FlowyIconButton(
          onPressed: () async {
            final delta = node.delta;
            if (delta == null) {
              return;
            }

            final document = Document.blank()
              ..insert([0], [node.deepCopy()])
              ..toJson();

            await getIt<ClipboardService>().setData(
              ClipboardServiceData(
                plainText: delta.toPlainText(),
                inAppJson: jsonEncode(document.toJson()),
              ),
            );

            if (context.mounted) {
              showToastNotification(
                message: LocaleKeys.document_codeBlock_codeCopiedSnackbar.tr(),
              );
            }
          },
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          icon: FlowySvg(
            FlowySvgs.copy_s,
            color: AFThemeExtension.of(context).textColor,
          ),
        ),
      ),
    );
  }
}
