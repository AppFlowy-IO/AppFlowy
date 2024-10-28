import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/shared/share/publish_color_extension.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublishedViewSettingsDialog extends StatefulWidget {
  const PublishedViewSettingsDialog({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  State<PublishedViewSettingsDialog> createState() =>
      _PublishedViewSettingsDialogState();
}

class _PublishedViewSettingsDialogState
    extends State<PublishedViewSettingsDialog> {
  final focusNode = FocusNode();
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.publishInfoView.info.publishName;
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
              _buildPublishNameLabel(),
              const VSpace(8),
              _buildPublishNameTextField(),
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
        Expanded(
          child: FlowyText(
            LocaleKeys.settings_sites_publishedPage_settings.tr(),
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

  Widget _buildPublishNameLabel() {
    return FlowyText(
      LocaleKeys.settings_sites_publishedPage_pathName.tr(),
      fontSize: 14.0,
      color: Theme.of(context).hintColor,
    );
  }

  Widget _buildPublishNameTextField() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: FlowyTextField(
              autoFocus: false,
              controller: controller,
              enableBorderColor: ShareMenuColors.borderColor(context),
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ),
        const HSpace(12.0),
        OutlinedRoundedButton(
          text: LocaleKeys.button_save.tr(),
          radius: 8.0,
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 11.0,
          ),
          onTap: _savePublishName,
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedRoundedButton(
          text: LocaleKeys.shareAction_unPublish.tr(),
          onTap: _unpublishView,
        ),
        const HSpace(12.0),
        PrimaryRoundedButton(
          text: LocaleKeys.shareAction_visitSite.tr(),
          radius: 8.0,
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 9.0,
          ),
          onTap: _visitSite,
        ),
      ],
    );
  }

  void _savePublishName() {
    context.read<SettingsSitesBloc>().add(
          SettingsSitesEvent.updatePublishName(
            widget.publishInfoView.info.viewId,
            controller.text,
          ),
        );
  }

  void _unpublishView() {
    context.read<SettingsSitesBloc>().add(
          SettingsSitesEvent.unpublishView(
            widget.publishInfoView.info.viewId,
          ),
        );

    Navigator.of(context).pop();
  }

  void _visitSite() {
    SettingsPageSitesEvent.visitSite(
      widget.publishInfoView,
      nameSpace: context.read<SettingsSitesBloc>().state.namespace,
    );
  }

  void _onListener(BuildContext context, SettingsSitesState state) {
    final actionResult = state.actionResult;
    final result = actionResult?.result;
    if (actionResult == null ||
        result == null ||
        actionResult.actionType != SettingsSitesActionType.updatePublishName) {
      return;
    }

    result.fold(
      (s) {
        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
        );
        Navigator.of(context).pop();
      },
      (f) {
        Log.error('update path name failed: $f');
        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_error_updatePathNameFailed.tr(),
          type: ToastificationType.error,
          description: f.msg,
        );
      },
    );
  }
}
