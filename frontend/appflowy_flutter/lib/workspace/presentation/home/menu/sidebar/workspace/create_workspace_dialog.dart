import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

Future<String?> showCreateWorkspaceDialog(
  BuildContext context, {
  required String userName,
}) {
  return showDialog<String?>(
    context: context,
    builder: (context) => CreateWorkspaceDialog(
      userName: userName,
    ),
  );
}

class CreateWorkspaceDialog extends StatefulWidget {
  const CreateWorkspaceDialog({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  State<CreateWorkspaceDialog> createState() => _CreateWorkspaceDialogState();
}

class _CreateWorkspaceDialogState extends State<CreateWorkspaceDialog> {
  late final TextEditingController textController;
  final focusNode = FocusNode();

  bool isEmpty = false;

  @override
  void initState() {
    super.initState();

    final text = widget.userName.isNotEmpty
        ? LocaleKeys.workspace_workspaceNameWithUserName
            .tr(args: [widget.userName])
        : LocaleKeys.workspace_workspaceNameFallback.tr();

    textController = TextEditingController()
      ..value = TextEditingValue(
        text: text,
        selection: TextSelection(baseOffset: 0, extentOffset: text.length),
      )
      ..addListener(() {
        setState(() => isEmpty = textController.text.isEmpty);
      });
    isEmpty = textController.text.isEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFModal(
      constraints: const BoxConstraints(
        maxWidth: 500,
        maxHeight: 250,
      ),
      child: Column(
        children: [
          AFModalHeader(
            leading: Text(
              LocaleKeys.workspace_createANewWorkspace.tr(),
              style: theme.textStyle.heading4.prominent(
                color: theme.textColorScheme.primary,
              ),
            ),
            trailing: [
              AFGhostButton.normal(
                onTap: () => Navigator.of(context).pop(),
                padding: EdgeInsets.all(theme.spacing.xs),
                builder: (context, isHovering, isDisabled) {
                  return Center(
                    child: FlowySvg(
                      FlowySvgs.toast_close_s,
                      size: Size.square(20),
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: AFModalBody(
              child: Column(
                children: [
                  _IconAndDescription(),
                  VSpace(
                    theme.spacing.xxl,
                  ),
                  _WorkspaceName(
                    textController: textController,
                    focusNode: focusNode,
                  ),
                ],
              ),
            ),
          ),
          AFModalFooter(
            trailing: [
              AFOutlinedTextButton.normal(
                onTap: () => Navigator.of(context).pop(),
                text: LocaleKeys.button_cancel.tr(),
              ),
              AFFilledTextButton.primary(
                disabled: isEmpty,
                text: LocaleKeys.button_create.tr(),
                onTap: handleCreateWorkspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void handleCreateWorkspace() {
    final workspaceName = textController.text;
    if (workspaceName.isEmpty) {
      return;
    }

    Navigator.of(context).pop(workspaceName);
  }
}

class _IconAndDescription extends StatelessWidget {
  const _IconAndDescription();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Row(
      children: [
        // FlowySvg(
        //   FlowySvgs.app_logo_s,
        //   size: Size.square(48),
        //   blendMode: null,
        // ),
        // HSpace(
        //   theme.spacing.xl,
        // ),
        Expanded(
          child: Text(
            LocaleKeys.workspace_createWorkspaceDescription.tr(),
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.secondary,
            ),
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}

class _WorkspaceName extends StatelessWidget {
  const _WorkspaceName({
    required this.textController,
    required this.focusNode,
  });

  final TextEditingController textController;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.workspace_workspaceName.tr(),
          style: theme.textStyle.caption.enhanced(
            color: theme.textColorScheme.secondary,
          ),
        ),
        VSpace(
          theme.spacing.xs,
        ),
        AFTextField(
          controller: textController,
          focusNode: focusNode,
          size: AFTextFieldSize.m,
          autoFocus: true,
        ),
      ],
    );
  }
}
