import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/billing/sidebar_plan_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarToast extends StatefulWidget {
  const SidebarToast({super.key});

  @override
  State<SidebarToast> createState() => _SidebarToastState();
}

class _SidebarToastState extends State<SidebarToast> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SidebarPlanBloc, SidebarPlanState>(
      listener: (context, state) {
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
      builder: (context, state) {
        return BlocBuilder<SidebarPlanBloc, SidebarPlanState>(
          builder: (context, state) {
            return state.tierIndicator.when(
              storageLimitHit: () => Column(
                children: [
                  const Divider(height: 0.6),
                  PlanIndicator(
                    planName: "Pro",
                    buttonTextKey: LocaleKeys.sideBar_upgradeToPro,
                    onTap: () {
                      _hanldeOnTap(context, SubscriptionPlanPB.Pro);
                    },
                    reason: LocaleKeys.sideBar_storageLimitDialogTitle.tr(),
                  ),
                ],
              ),
              aiMaxiLimitHit: () => Column(
                children: [
                  const Divider(height: 0.6),
                  PlanIndicator(
                    planName: "AI Max",
                    buttonTextKey: LocaleKeys.sideBar_upgradeToAIMax,
                    onTap: () {
                      _hanldeOnTap(context, SubscriptionPlanPB.AiMax);
                    },
                    reason: LocaleKeys.sideBar_aiResponseLitmitDialogTitle.tr(),
                  ),
                ],
              ),
              loading: () {
                return const SizedBox.shrink();
              },
            );
          },
        );
      },
    );
  }

  void _showStorageLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (dialogContext) => _StorageLimitDialog(
        onOkPressed: () {
          final userProfile = context.read<SidebarPlanBloc>().state.userProfile;
          final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
          if (userProfile != null) {
            showSettingsDialog(
              context,
              userProfile,
              userWorkspaceBloc,
              SettingsPage.plan,
            );
          } else {
            Log.error(
              "UserProfile is null. It should not happen. If you see this error, it's a bug.",
            );
          }
        },
      ),
    );
  }

  void _hanldeOnTap(BuildContext context, SubscriptionPlanPB plan) {
    final userProfile = context.read<SidebarPlanBloc>().state.userProfile;
    final userWorkspaceBloc = context.read<UserWorkspaceBloc>();
    if (userProfile != null) {
      showSettingsDialog(
        context,
        userProfile,
        userWorkspaceBloc,
        SettingsPage.plan,
      );
    }
  }
}

class PlanIndicator extends StatelessWidget {
  const PlanIndicator({
    required this.planName,
    required this.buttonTextKey,
    required this.onTap,
    required this.reason,
    super.key,
  });

  final String planName;
  final String reason;
  final String buttonTextKey;
  final Function() onTap;

  final textColor = const Color(0xFFE8E2EE);
  final secondaryColor = const Color(0xFF653E8C);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyButton(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          text: FlowyText(
            buttonTextKey.tr(),
            color: textColor,
            fontSize: 12,
          ),
          radius: BorderRadius.zero,
          leftIconSize: const Size(40, 20),
          leftIcon: Badge(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            backgroundColor: secondaryColor,
            label: FlowyText.semibold(
              planName,
              fontSize: 12,
              color: textColor,
            ),
          ),
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12, bottom: 6),
          child: Opacity(
            opacity: 0.4,
            child: FlowyText(
              reason,
              textAlign: TextAlign.start,
              color: textColor,
              fontSize: 10,
              maxLines: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _StorageLimitDialog extends StatelessWidget {
  const _StorageLimitDialog({
    required this.onOkPressed,
  });
  final VoidCallback onOkPressed;

  @override
  Widget build(BuildContext context) {
    return NavigatorOkCancelDialog(
      message: LocaleKeys.sideBar_storageLimitDialogTitle.tr(),
      okTitle: LocaleKeys.sideBar_purchaseStorageSpace.tr(),
      onOkPressed: onOkPressed,
      titleUpperCase: false,
    );
  }
}
