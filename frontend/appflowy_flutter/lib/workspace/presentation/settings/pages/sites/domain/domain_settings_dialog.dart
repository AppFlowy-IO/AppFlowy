import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/publish_color_extension.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DomainSettingsDialog extends StatefulWidget {
  const DomainSettingsDialog({
    super.key,
    required this.namespace,
  });

  final String namespace;

  @override
  State<DomainSettingsDialog> createState() => _DomainSettingsDialogState();
}

class _DomainSettingsDialogState extends State<DomainSettingsDialog> {
  final focusNode = FocusNode();
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.namespace;
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsSitesBloc, SettingsSitesState>(
      listener: _onListener,
      child: KeyboardListener(
        focusNode: focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              const VSpace(20),
              _buildNamespaceLabel(),
              const VSpace(8),
              _buildNamespaceTextField(),
              const VSpace(20),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        const Expanded(
          child: FlowyText(
            'Namespace settings',
            fontSize: 16.0,
            figmaLineHeight: 22.0,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const HSpace(6.0),
        FlowyButton(
          margin: const EdgeInsets.all(3),
          useIntrinsicWidth: true,
          text: const FlowySvg(
            FlowySvgs.upgrade_close_s,
            size: Size.square(18.0),
          ),
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildNamespaceLabel() {
    return FlowyText(
      'Namespace',
      fontSize: 14.0,
      color: Theme.of(context).hintColor,
    );
  }

  Widget _buildNamespaceTextField() {
    return SizedBox(
      height: 36,
      child: FlowyTextField(
        autoFocus: false,
        controller: controller,
        enableBorderColor: ShareMenuColors.borderColor(context),
        prefixIcon: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HSpace(12.0),
            FlowyText(
              'appflowy.com',
              fontSize: 14.0,
              figmaLineHeight: 36.0,
            ),
            VerticalDivider(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedRoundedButton(
          text: 'Cancel',
          onTap: () => Navigator.of(context).pop(),
        ),
        const HSpace(12.0),
        PrimaryRoundedButton(
          text: LocaleKeys.button_save.tr(),
          radius: 8.0,
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 9.0,
          ),
          onTap: _onSave,
        ),
      ],
    );
  }

  void _onSave() {
    // listen on the result
    context.read<SettingsSitesBloc>().add(
          SettingsSitesEvent.updateNamespace(controller.text),
        );
  }

  void _onListener(BuildContext context, SettingsSitesState state) {
    final actionResult = state.actionResult;
    final type = actionResult?.actionType;
    final result = actionResult?.result;
    if (type != SettingsSitesActionType.updateNamespace || result == null) {
      return;
    }

    result.fold(
      (s) {
        showToastNotification(context, message: 'Update namespace success');
        Navigator.of(context).pop();
      },
      (f) {
        showToastNotification(
          context,
          message: 'Update namespace failed',
          type: ToastificationType.error,
        );
      },
    );
  }
}
