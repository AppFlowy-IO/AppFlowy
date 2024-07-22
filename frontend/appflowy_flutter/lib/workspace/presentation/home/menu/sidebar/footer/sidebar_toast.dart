import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/billing/sidebar_plan_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
          storageLimitHit: () {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _showStorageLimitDialog(context),
              debugLabel: 'Sidebar.showStorageLimit',
            );
          },
          orElse: () {
            // Do nothing
          },
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
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();

    if (userProfile == null) {
      return Log.error(
        'UserProfile is null, this should NOT happen! Please file a bug report',
      );
    }

    showSettingsDialog(
      context,
      userProfile,
      userWorkspaceBloc,
      SettingsPage.plan,
    );
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
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Theme.of(context).isLightMode
            ? const Color(0x66F5EAFF)
            : const Color(0x1AFFFFFF),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Color(0x339327FF),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FlowySvg(
                FlowySvgs.upgrade_storage_s,
                blendMode: null,
              ),
              const HSpace(6),
              FlowyText(
                widget.text,
                color: AFThemeExtension.of(context).strongText,
              ),
            ],
          ),
          const VSpace(6),
          Opacity(
            opacity: 0.7,
            child: FlowyText.regular(
              widget.reason,
              maxLines: null,
              fontSize: 13,
              lineHeight: 1.3,
            ),
          ),
          const VSpace(6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: ShapeDecoration(
                  color: const Color(0xFFA44AFD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: FlowyText(
                  LocaleKeys.settings_comparePlanDialog_actions_upgrade.tr(),
                  color: Colors.white,
                  fontSize: 12,
                  strutStyle: const StrutStyle(forceStrutHeight: true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
