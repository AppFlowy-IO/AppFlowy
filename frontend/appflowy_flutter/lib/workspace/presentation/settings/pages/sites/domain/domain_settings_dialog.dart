import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/plugins/shared/share/publish_color_extension.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
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
  late final controllerText = ValueNotifier<String>(widget.namespace);
  String errorHintText = '';

  @override
  void initState() {
    super.initState();

    controller.text = widget.namespace;
    controller.addListener(() {
      controllerText.value = controller.text;
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    controllerText.dispose();

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
              const VSpace(12),
              _buildNamespaceDescription(),
              const VSpace(20),
              _buildNamespaceTextField(),
              _buildPreviewNamespace(),
              _buildErrorHintText(),
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
        FlowyText(
          LocaleKeys.settings_sites_namespace_updateExistingNamespace.tr(),
          fontSize: 16.0,
          figmaLineHeight: 22.0,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        const HSpace(6.0),
        FlowyTooltip(
          message: LocaleKeys.settings_sites_namespace_tooltip.tr(),
          child: const FlowySvg(FlowySvgs.information_s),
        ),
        const HSpace(6.0),
        const Spacer(),
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

  Widget _buildNamespaceDescription() {
    return FlowyText(
      LocaleKeys.settings_sites_namespace_description.tr(),
      fontSize: 14.0,
      color: Theme.of(context).hintColor,
      figmaLineHeight: 16.0,
      maxLines: 3,
    );
  }

  Widget _buildNamespaceTextField() {
    return SizedBox(
      height: 36,
      child: FlowyTextField(
        autoFocus: false,
        controller: controller,
        enableBorderColor: ShareMenuColors.borderColor(context),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedRoundedButton(
          text: LocaleKeys.button_cancel.tr(),
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

  Widget _buildErrorHintText() {
    if (errorHintText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, left: 2.0),
      child: FlowyText(
        errorHintText,
        fontSize: 12.0,
        figmaLineHeight: 18.0,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Widget _buildPreviewNamespace() {
    return ValueListenableBuilder<String>(
      valueListenable: controllerText,
      builder: (context, value, child) {
        final url = ShareConstants.buildNamespaceUrl(
          nameSpace: value,
        );
        return Padding(
          padding: const EdgeInsets.only(top: 4.0, left: 2.0),
          child: Opacity(
            opacity: 0.8,
            child: FlowyText(
              url,
              fontSize: 14.0,
              figmaLineHeight: 18.0,
            ),
          ),
        );
      },
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
        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_success_namespaceUpdated.tr(),
        );
        Navigator.of(context).pop();
      },
      (f) {
        final basicErrorMessage =
            LocaleKeys.settings_sites_error_failedToUpdateNamespace.tr();
        final errorMessage = _localizeErrorMessage(f.code);

        setState(() {
          errorHintText = errorMessage.orDefault(basicErrorMessage);
        });

        final toastMessage = errorMessage.isEmpty
            ? basicErrorMessage
            : '$basicErrorMessage: $errorMessage';

        showToastNotification(
          context,
          message: toastMessage,
          type: ToastificationType.error,
        );
      },
    );
  }

  String _localizeErrorMessage(ErrorCode code) {
    return switch (code) {
      ErrorCode.CustomNamespaceRequirePlanUpgrade =>
        LocaleKeys.settings_sites_error_proPlanLimitation.tr(),
      ErrorCode.CustomNamespaceAlreadyTaken =>
        LocaleKeys.settings_sites_error_namespaceAlreadyInUse.tr(),
      ErrorCode.InvalidNamespace =>
        LocaleKeys.settings_sites_error_invalidNamespace.tr(),
      ErrorCode.CustomNamespaceNotAllowed =>
        LocaleKeys.settings_sites_error_namespaceLengthAtLeast2Characters.tr(),
      _ => '',
    };
  }
}
