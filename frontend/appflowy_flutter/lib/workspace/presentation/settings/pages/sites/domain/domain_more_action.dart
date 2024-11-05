import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/constants.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_settings_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DomainMoreAction extends StatefulWidget {
  const DomainMoreAction({
    super.key,
    required this.namespace,
  });

  final String namespace;

  @override
  State<DomainMoreAction> createState() => _DomainMoreActionState();
}

class _DomainMoreActionState extends State<DomainMoreAction> {
  @override
  void initState() {
    super.initState();

    // update the current workspace to ensure the owner check is correct
    context.read<UserWorkspaceBloc>().add(const UserWorkspaceEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: const BoxConstraints(maxWidth: 188),
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
          child: _buildUpdateNamespaceButton(
            context,
            builderContext,
          ),
        );
      },
    );
  }

  Widget _buildUpdateNamespaceButton(
    BuildContext context,
    BuildContext builderContext,
  ) {
    final child = _buildActionButton(
      context,
      builderContext,
      type: _ActionType.updateNamespace,
    );

    final plan = context.read<SettingsSitesBloc>().state.subscriptionInfo?.plan;

    if (plan != WorkspacePlanPB.ProPlan) {
      return _buildForbiddenActionButton(
        context,
        tooltipMessage: LocaleKeys.settings_sites_namespace_upgradeToPro.tr(),
        child: child,
      );
    }

    final isOwner = context
            .watch<UserWorkspaceBloc>()
            .state
            .currentWorkspaceMember
            ?.role
            .isOwner ??
        false;

    if (!isOwner) {
      return _buildForbiddenActionButton(
        context,
        tooltipMessage: LocaleKeys
            .settings_sites_error_onlyWorkspaceOwnerCanUpdateNamespace
            .tr(),
        child: child,
      );
    }

    return child;
  }

  Widget _buildForbiddenActionButton(
    BuildContext context, {
    required String tooltipMessage,
    required Widget child,
  }) {
    return Opacity(
      opacity: 0.5,
      child: FlowyTooltip(
        message: tooltipMessage,
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: IgnorePointer(child: child),
        ),
      ),
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
          overflow: TextOverflow.ellipsis,
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
      case _ActionType.updateNamespace:
        _showSettingsDialog(
          context,
          builderContext,
        );
        break;
      case _ActionType.removeHomePage:
        context.read<SettingsSitesBloc>().add(
              const SettingsSitesEvent.removeHomePage(),
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
              width: 460,
              child: DomainSettingsDialog(
                namespace: widget.namespace,
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ActionType {
  updateNamespace,
  removeHomePage,
}

extension _ActionTypeExtension on _ActionType {
  String get name => switch (this) {
        _ActionType.updateNamespace =>
          LocaleKeys.settings_sites_updateNamespace.tr(),
        _ActionType.removeHomePage =>
          LocaleKeys.settings_sites_removeHomepage.tr(),
      };

  FlowySvgData get leftIconSvg => switch (this) {
        _ActionType.updateNamespace => FlowySvgs.view_item_rename_s,
        _ActionType.removeHomePage => FlowySvgs.trash_s,
      };
}
