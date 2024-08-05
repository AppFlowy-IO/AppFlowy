import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/billing/sidebar_plan_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarToast extends StatelessWidget {
  const SidebarToast({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SidebarPlanBloc, SidebarPlanState>(
      listener: (_, state) {
        // Show a dialog when the user hits the storage limit, After user click ok, it will navigate to the plan page.
        // Even though the dislog is dissmissed, if the user triggers the storage limit again, the dialog will show again.
        state.tierIndicator.maybeWhen(
          storageLimitHit: () => WidgetsBinding.instance.addPostFrameCallback(
            (_) => _showStorageLimitDialog(context),
          ),
          orElse: () {},
        );
      },
      builder: (_, state) {
        return state.tierIndicator.when(
          loading: () => const SizedBox.shrink(),
          storageLimitHit: () => PlanIndicator(
            planName: SubscriptionPlanPB.Free.label,
            text: LocaleKeys.sideBar_upgradeToPro.tr(),
            onTap: () => _hanldeOnTap(context, SubscriptionPlanPB.Pro),
            reason: LocaleKeys.sideBar_storageLimitDialogTitle.tr(),
          ),
          aiMaxiLimitHit: () => PlanIndicator(
            planName: SubscriptionPlanPB.AiMax.label,
            text: LocaleKeys.sideBar_upgradeToAIMax.tr(),
            onTap: () => _hanldeOnTap(context, SubscriptionPlanPB.AiMax),
            reason: LocaleKeys.sideBar_aiResponseLimitTitle.tr(),
          ),
        );
      },
    );
  }

  void _showStorageLimitDialog(BuildContext context) => showConfirmDialog(
        context: context,
        title: LocaleKeys.sideBar_purchaseStorageSpace.tr(),
        description: LocaleKeys.sideBar_storageLimitDialogTitle.tr(),
        confirmLabel:
            LocaleKeys.settings_comparePlanDialog_actions_upgrade.tr(),
        onConfirm: () {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _hanldeOnTap(context, SubscriptionPlanPB.Pro),
          );
        },
      );

  void _hanldeOnTap(BuildContext context, SubscriptionPlanPB plan) {
    final userProfile = context.read<SidebarPlanBloc>().state.userProfile;
    if (userProfile == null) {
      return Log.error(
        'UserProfile is null, this should NOT happen! Please file a bug report',
      );
    }

    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    final member = userWorkspaceBloc.state.currentWorkspaceMember;
    if (member == null) {
      return Log.error(
        "Member is null. It should not happen. If you see this error, it's a bug",
      );
    }

    // Only if the user is the workspace owner will we navigate to the plan page.
    if (member.role.isOwner) {
      showSettingsDialog(
        context,
        userProfile,
        userWorkspaceBloc,
        SettingsPage.plan,
      );
    } else {
      final message = plan == SubscriptionPlanPB.AiMax
          ? LocaleKeys.sideBar_askOwnerToUpgradeToAIMax.tr()
          : LocaleKeys.sideBar_askOwnerToUpgradeToPro.tr();

      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: false,
        builder: (dialogContext) => _AskOwnerToChangePlan(
          message: message,
          onOkPressed: () {},
        ),
      );
    }
  }
}

class PlanIndicator extends StatefulWidget {
  const PlanIndicator({
    super.key,
    required this.planName,
    required this.text,
    required this.onTap,
    required this.reason,
  });

  final String planName;
  final String reason;
  final String text;
  final Function() onTap;

  @override
  State<PlanIndicator> createState() => _PlanIndicatorState();
}

class _PlanIndicatorState extends State<PlanIndicator> {
  final popoverController = PopoverController();

  @override
  void dispose() {
    popoverController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textGradient = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8032FF), Color(0xFFEF35FF)],
      stops: [0.1545, 0.8225],
    );

    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF8032FF).withOpacity(.1),
        const Color(0xFFEF35FF).withOpacity(.1),
      ],
    );

    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.rightWithBottomAligned,
      offset: const Offset(10, -12),
      popupBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowyText(
                widget.text,
                color: AFThemeExtension.of(context).strongText,
              ),
              const VSpace(12),
              Opacity(
                opacity: 0.7,
                child: FlowyText.regular(
                  widget.reason,
                  maxLines: null,
                  lineHeight: 1.3,
                  textAlign: TextAlign.center,
                ),
              ),
              const VSpace(12),
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          popoverController.close();
                          widget.onTap();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Center(
                            child: FlowyText(
                              LocaleKeys
                                  .settings_comparePlanDialog_actions_upgrade
                                  .tr(),
                              color: Colors.white,
                              fontSize: 12,
                              strutStyle: const StrutStyle(
                                forceStrutHeight: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const FlowySvg(
                FlowySvgs.upgrade_storage_s,
                blendMode: null,
              ),
              const HSpace(6),
              ShaderMask(
                shaderCallback: (bounds) => textGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: FlowyText(
                  widget.text,
                  color: AFThemeExtension.of(context).strongText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AskOwnerToChangePlan extends StatelessWidget {
  const _AskOwnerToChangePlan({
    required this.message,
    required this.onOkPressed,
  });
  final String message;
  final VoidCallback onOkPressed;

  @override
  Widget build(BuildContext context) {
    return NavigatorOkCancelDialog(
      message: message,
      okTitle: LocaleKeys.button_ok.tr(),
      onOkPressed: onOkPressed,
      titleUpperCase: false,
    );
  }
}
