import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_on_boarding_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/local_ai_setting.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/model_selection.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/foundation.dart';
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
  const SettingsAIView({
    super.key,
    required this.userProfile,
    required this.member,
    required this.workspaceId,
  });

  final UserProfilePB userProfile;
  final WorkspaceMemberPB? member;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsAIBloc>(
      create: (_) => SettingsAIBloc(userProfile, workspaceId, member)
        ..add(const SettingsAIEvent.started()),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          final children = <Widget>[
            const AIModelSelection(),
          ];

          children.add(const _AISearchToggle(value: false));

          if (state.member != null) {
            children.add(
              _LocalAIOnBoarding(
                userProfile: userProfile,
                member: state.member!,
                workspaceId: workspaceId,
              ),
            );
          }

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

// ignore: unused_element
class _LocalAIOnBoarding extends StatelessWidget {
  const _LocalAIOnBoarding({
    required this.userProfile,
    required this.member,
    required this.workspaceId,
  });
  final UserProfilePB userProfile;
  final WorkspaceMemberPB member;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    if (FeatureFlag.planBilling.isOn) {
      return BillingGateGuard(
        builder: (context) {
          return BlocProvider(
            create: (context) =>
                LocalAIOnBoardingBloc(userProfile, member, workspaceId)
                  ..add(const LocalAIOnBoardingEvent.started()),
            child: BlocBuilder<LocalAIOnBoardingBloc, LocalAIOnBoardingState>(
              builder: (context, state) {
                // Show the local AI settings if the user has purchased the AI Local plan
                if (kDebugMode || state.isPurchaseAILocal) {
                  return const LocalAISetting();
                } else {
                  if (member.role.isOwner) {
                    // Show the upgrade to AI Local plan button if the user has not purchased the AI Local plan
                    return _UpgradeToAILocalPlan(
                      onTap: () {
                        context.read<LocalAIOnBoardingBloc>().add(
                              const LocalAIOnBoardingEvent.addSubscription(
                                SubscriptionPlanPB.AiLocal,
                              ),
                            );
                      },
                    );
                  } else {
                    return const _AskOwnerUpgradeToLocalAI();
                  }
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

class _AskOwnerUpgradeToLocalAI extends StatelessWidget {
  const _AskOwnerUpgradeToLocalAI();

  @override
  Widget build(BuildContext context) {
    return FlowyText(
      LocaleKeys.sideBar_askOwnerToUpgradeToLocalAI.tr(),
      color: AFThemeExtension.of(context).strongText,
    );
  }
}

class _UpgradeToAILocalPlan extends StatefulWidget {
  const _UpgradeToAILocalPlan({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_UpgradeToAILocalPlan> createState() => _UpgradeToAILocalPlanState();
}

class _UpgradeToAILocalPlanState extends State<_UpgradeToAILocalPlan> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowyText.medium(
                LocaleKeys.sideBar_upgradeToAILocal.tr(),
                maxLines: 10,
                lineHeight: 1.5,
              ),
              const VSpace(4),
              Opacity(
                opacity: 0.6,
                child: FlowyText(
                  LocaleKeys.sideBar_upgradeToAILocalDesc.tr(),
                  fontSize: 12,
                  maxLines: 10,
                  lineHeight: 1.5,
                ),
              ),
            ],
          ),
        ),
        BlocBuilder<LocalAIOnBoardingBloc, LocalAIOnBoardingState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const CircularProgressIndicator.adaptive();
            } else {
              return Toggle(
                value: false,
                onChanged: (_) => widget.onTap(),
              );
            }
          },
        ),
      ],
    );
  }
}
