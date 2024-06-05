import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/mobile_block_action_buttons.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      _ErrorBlockComponentWidgetState();
}

class _ErrorBlockComponentWidgetState extends State<ErrorBlockComponentWidget>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  Widget build(BuildContext context) {
    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        text: PlatformExtension.isDesktopOrWeb
            ? _buildDesktopErrorBlock(context)
            : _buildMobileErrorBlock(context),
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

    if (PlatformExtension.isMobile) {
      child = MobileBlockActionButtons(
        node: node,
        editorState: context.read<EditorState>(),
        child: child,
      );
    }

    return child;
  }

  Widget _buildDesktopErrorBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const HSpace(4),
          FlowyText.regular(
            LocaleKeys.document_errorBlock_theBlockIsNotSupported.tr(),
          ),
          const HSpace(4),
          FlowyText.regular(
            '(${LocaleKeys.document_errorBlock_clickToCopyTheBlockContent.tr()})',
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileErrorBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.regular(
            LocaleKeys.document_errorBlock_theBlockIsNotSupported.tr(),
          ),
          const VSpace(6),
          FlowyText.regular(
            '(${LocaleKeys.document_errorBlock_clickToCopyTheBlockContent.tr()})',
            color: Theme.of(context).hintColor,
            fontSize: 12.0,
          ),
        ],
      ),
    );
  }
}
