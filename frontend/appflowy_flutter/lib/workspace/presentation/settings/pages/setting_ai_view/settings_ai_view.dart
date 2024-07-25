import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_on_boarding_bloc.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/local_ai_setting.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/model_selection.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIFeatureOnlySupportedWhenUsingAppFlowyCloud extends StatelessWidget {
  const AIFeatureOnlySupportedWhenUsingAppFlowyCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
      child: FlowyText(
        LocaleKeys.settings_aiPage_keys_loginToEnableAIFeature.tr(),
        maxLines: null,
        fontSize: 16,
        lineHeight: 1.6,
      ),
    );
  }
}

class SettingsAIView extends StatelessWidget {
  const SettingsAIView({super.key, required this.userProfile});

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsAIBloc>(
      create: (_) =>
          SettingsAIBloc(userProfile)..add(const SettingsAIEvent.started()),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          final children = <Widget>[
            const AIModelSelection(),
          ];

          children.add(const _AISearchToggle(value: false));
          children.add(const _LocalAIOnBoarding());

          return SettingsBody(
            title: LocaleKeys.settings_aiPage_title.tr(),
            description:
                LocaleKeys.settings_aiPage_keys_aiSettingsDescription.tr(),
            children: children,
          );
        },
      ),
    );
  }
}

class _AISearchToggle extends StatelessWidget {
  const _AISearchToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FlowyText.medium(
              LocaleKeys.settings_aiPage_keys_enableAISearchTitle.tr(),
            ),
            const Spacer(),
            BlocBuilder<SettingsAIBloc, SettingsAIState>(
              builder: (context, state) {
                if (state.aiSettings == null) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: SizedBox(
                      height: 26,
                      width: 26,
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  );
                } else {
                  return Toggle(
                    value: state.enableSearchIndexing,
                    onChanged: (_) => context
                        .read<SettingsAIBloc>()
                        .add(const SettingsAIEvent.toggleAISearch()),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _LocalAIOnBoarding extends StatelessWidget {
  const _LocalAIOnBoarding();

  @override
  Widget build(BuildContext context) {
    if (FeatureFlag.planBilling.isOn) {
      return BillingGateGuard(
        builder: (context) {
          return BlocProvider(
            create: (context) => LocalAIOnBoardingBloc()
              ..add(const LocalAIOnBoardingEvent.started()),
            child: BlocBuilder<LocalAIOnBoardingBloc, LocalAIOnBoardingState>(
              builder: (context, state) {
                // Show the local AI settings if the user has purchased the AI Local plan
                if (state.isPurchaseAILocal) {
                  return const LocalAISetting();
                } else {
                  // Show the upgrade to AI Local plan button if the user has not purchased the AI Local plan
                  return _UpgradeToAILocalPlan(
                    onTap: () {
                      context.read<SettingsDialogBloc>().add(
                            const SettingsDialogEvent.setSelectedPage(
                              SettingsPage.plan,
                            ),
                          );
                    },
                  );
                }
              },
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _UpgradeToAILocalPlan extends StatefulWidget {
  const _UpgradeToAILocalPlan({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_UpgradeToAILocalPlan> createState() => _UpgradeToAILocalPlanState();
}

class _UpgradeToAILocalPlanState extends State<_UpgradeToAILocalPlan> {
  bool _isHovered = false;

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
        _isHovered
            ? const Color(0xFF8032FF).withOpacity(0.3)
            : Colors.transparent,
        _isHovered
            ? const Color(0xFFEF35FF).withOpacity(0.3)
            : Colors.transparent,
      ],
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
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
                  LocaleKeys.sideBar_upgradeToAILocal.tr(),
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
