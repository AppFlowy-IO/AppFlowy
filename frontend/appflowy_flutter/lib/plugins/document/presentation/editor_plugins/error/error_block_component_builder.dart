import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ErrorBlockComponentBuilder extends BlockComponentBuilder {
  ErrorBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ErrorBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  bool validate(Node node) => true;
}

class ErrorBlockComponentWidget extends BlockComponentStatefulWidget {
  const ErrorBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<ErrorBlockComponentWidget> createState() =>
      _DividerBlockComponentWidgetState();
}

class _DividerBlockComponentWidgetState extends State<ErrorBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  Widget build(BuildContext context) {
    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyButton(
        onTap: () async {
          showSnackBarMessage(
            context,
            LocaleKeys.document_errorBlock_blockContentHasBeenCopied.tr(),
          );
          await getIt<ClipboardService>().setData(
            ClipboardServiceData(plainText: jsonEncode(node.toJson())),
          );
        },
        text: Container(
          height: 48,
          alignment: Alignment.center,
          child: FlowyText(
            LocaleKeys.document_errorBlock_theBlockIsNotSupported.tr(),
          ),
        ),
      ),
    );

    child = Padding(
      padding: padding,
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }
}
