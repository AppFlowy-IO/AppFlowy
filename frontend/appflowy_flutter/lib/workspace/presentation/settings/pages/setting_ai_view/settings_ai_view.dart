import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/ai/local_ai_on_boarding_bloc.dart';
import 'package:appflowy/workspace/application/settings/ai/settings_ai_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/local_ai_setting.dart';
import 'package:appflowy/workspace/presentation/settings/pages/setting_ai_view/model_selection.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_appflowy_cloud.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
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
    required this.currentWorkspaceMemberRole,
    required this.workspaceId,
  });

  final UserProfilePB userProfile;
  final AFRolePB? currentWorkspaceMemberRole;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsAIBloc>(
      create: (_) =>
          SettingsAIBloc(userProfile, workspaceId, currentWorkspaceMemberRole)
            ..add(const SettingsAIEvent.started()),
      child: BlocBuilder<SettingsAIBloc, SettingsAIState>(
        builder: (context, state) {
          final children = <Widget>[
            const AIModelSelection(),
          ];

          children.add(const _AISearchToggle(value: false));
          children.add(const LocalAISetting());

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
    required this.currentWorkspaceMemberRole,
    required this.workspaceId,
  });
  final UserProfilePB userProfile;
  final AFRolePB? currentWorkspaceMemberRole;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    if (FeatureFlag.planBilling.isOn) {
      return BillingGateGuard(
        builder: (context) {
          return BlocProvider(
            create: (context) => LocalAIOnBoardingBloc(
              userProfile,
              currentWorkspaceMemberRole,
              workspaceId,
            )..add(const LocalAIOnBoardingEvent.started()),
            child: BlocBuilder<LocalAIOnBoardingBloc, LocalAIOnBoardingState>(
              builder: (context, state) {
                return const LocalAISetting();
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
