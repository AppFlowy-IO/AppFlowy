import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/billing/sidebar_toast_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_setting.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarToast extends StatelessWidget {
  const SidebarToast({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarToastBloc, SidebarToastState>(
      builder: (context, state) {
        return state.tierIndicator.when(
          proTier: () => Column(
            children: [
              const Divider(height: 0.6),
              ProPlanIndicator(
                onTap: (plan) => _hanldeOnTap(context, plan),
              ),
            ],
          ),
          aiMaxTier: () => Column(
            children: [
              const Divider(height: 0.6),
              AIMaxIndicator(
                onTap: (plan) => _hanldeOnTap(context, plan),
              ),
            ],
          ),
          hide: () {
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  void _hanldeOnTap(BuildContext context, SubscriptionPlanPB plan) {
    final userProfile = context.read<SidebarToastBloc>().state.userProfile;
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

class AIMaxIndicator extends StatelessWidget {
  const AIMaxIndicator({required this.onTap, super.key});
  final primaryColor = const Color(0xFFE8E2EE);
  final secondaryColor = const Color(0xFF653E8C);
  final Function(SubscriptionPlanPB) onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      text: FlowyText(
        LocaleKeys.sideBar_upgradeToAIMax.tr(),
        color: primaryColor,
        fontSize: 12,
      ),
      radius: BorderRadius.zero,
      leftIconSize: const Size(40, 20),
      leftIcon: Badge(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: secondaryColor,
        label: FlowyText.semibold(
          "AI Max",
          fontSize: 12,
          color: primaryColor,
        ),
      ),
      onTap: () => onTap(SubscriptionPlanPB.AiMax),
    );
  }
}

class ProPlanIndicator extends StatelessWidget {
  const ProPlanIndicator({required this.onTap, super.key});
  final primaryColor = const Color(0xFFE8E2EE);
  final secondaryColor = const Color(0xFF653E8C);
  final Function(SubscriptionPlanPB) onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      text: FlowyText(
        LocaleKeys.sideBar_upgradeToPro.tr(),
        color: primaryColor,
        fontSize: 12,
      ),
      radius: BorderRadius.zero,
      leftIconSize: const Size(40, 20),
      leftIcon: Badge(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        backgroundColor: secondaryColor,
        label: FlowyText.semibold(
          "Pro",
          fontSize: 12,
          color: primaryColor,
        ),
      ),
      onTap: () => onTap(SubscriptionPlanPB.Pro),
    );
  }
}
