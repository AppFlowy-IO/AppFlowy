import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublishedViewMoreAction extends StatelessWidget {
  const PublishedViewMoreAction({
    super.key,
    required this.publishInfoView,
  });

  final PublishInfoViewPB publishInfoView;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(maxWidth: 168),
      offset: const Offset(6, 0),
      animationDuration: Durations.short3,
      beginScaleFactor: 1.0,
      beginOpacity: 0.8,
      child: const SizedBox(
        width: SettingsPageSitesConstants.threeDotsButtonWidth,
        child: FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(FlowySvgs.three_dots_s),
        ),
      ),
      popupBuilder: (builderContext) {
        return BlocProvider.value(
          value: context.read<SettingsSitesBloc>(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context,
                builderContext,
                type: _ActionType.viewSite,
              ),
              _buildActionButton(
                context,
                builderContext,
                type: _ActionType.copySiteLink,
              ),
              _buildActionButton(
                context,
                builderContext,
                type: _ActionType.unpublish,
              ),
              _buildActionButton(
                context,
                builderContext,
                type: _ActionType.customUrl,
              ),
              _buildActionButton(
                context,
                builderContext,
                type: _ActionType.settings,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    BuildContext builderContext, {
    required _ActionType type,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyIconTextButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        iconPadding: 10.0,
        onTap: () => _onTap(context, builderContext, type),
        leftIconBuilder: (onHover) => FlowySvg(
          type.leftIconSvg,
        ),
        textBuilder: (onHover) => FlowyText.regular(
          type.name,
          fontSize: 14.0,
          figmaLineHeight: 18.0,
        ),
      ),
    );
  }

  void _onTap(
    BuildContext context,
    BuildContext builderContext,
    _ActionType type,
  ) {
    switch (type) {
      case _ActionType.viewSite:
        SettingsPageSitesEvent.visitSite(
          publishInfoView,
          nameSpace: context.read<SettingsSitesBloc>().state.namespace,
        );
        break;
      case _ActionType.copySiteLink:
        SettingsPageSitesEvent.copySiteLink(
          context,
          publishInfoView,
          nameSpace: context.read<SettingsSitesBloc>().state.namespace,
        );
        break;
      case _ActionType.settings:
        _showSettingsDialog(
          context,
          builderContext,
        );
        break;
      case _ActionType.unpublish:
        context.read<SettingsSitesBloc>().add(
              SettingsSitesEvent.unpublishView(publishInfoView.info.viewId),
            );
        PopoverContainer.maybeOf(builderContext)?.close();
        break;
      case _ActionType.customUrl:
        _showSettingsDialog(
          context,
          builderContext,
        );
        break;
    }

    PopoverContainer.of(builderContext).closeAll();
  }

  void _showSettingsDialog(
    BuildContext context,
    BuildContext builderContext,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<SettingsSitesBloc>(),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: SizedBox(
              width: 440,
              child: PublishedViewSettingsDialog(
                publishInfoView: publishInfoView,
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ActionType {
  viewSite,
  copySiteLink,
  settings,
  unpublish,
  customUrl;

  String get name => switch (this) {
        _ActionType.viewSite => LocaleKeys.shareAction_visitSite.tr(),
        _ActionType.copySiteLink => LocaleKeys.shareAction_copyLink.tr(),
        _ActionType.settings => LocaleKeys.settings_popupMenuItem_settings.tr(),
        _ActionType.unpublish => LocaleKeys.shareAction_unPublish.tr(),
        _ActionType.customUrl => LocaleKeys.settings_sites_customUrl.tr(),
      };

  FlowySvgData get leftIconSvg => switch (this) {
        _ActionType.viewSite => FlowySvgs.share_publish_s,
        _ActionType.copySiteLink => FlowySvgs.copy_s,
        _ActionType.settings => FlowySvgs.settings_s,
        _ActionType.unpublish => FlowySvgs.delete_s,
        _ActionType.customUrl => FlowySvgs.edit_s,
      };
}
