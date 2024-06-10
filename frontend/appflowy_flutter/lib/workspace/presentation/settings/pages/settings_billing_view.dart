import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/workspace/application/settings/billing/settings_billing_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';

class SettingsBillingView extends StatelessWidget {
  const SettingsBillingView({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBillingBloc>(
      create: (context) => SettingsBillingBloc(workspaceId: workspaceId)
        ..add(const SettingsBillingEvent.started()),
      child: BlocBuilder<SettingsBillingBloc, SettingsBillingState>(
        builder: (context, state) {
          return state.map(
            initial: (_) => const SizedBox.shrink(),
            loading: (_) => const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator.adaptive(strokeWidth: 3),
              ),
            ),
            error: (state) {
              if (state.error != null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: FlowyErrorPage.message(
                    state.error!.msg,
                    howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
                  ),
                );
              }

              return ErrorWidget.withDetails(message: 'Something went wrong!');
            },
            ready: (state) {
              return SettingsBody(
                title: LocaleKeys.settings_billingPage_title.tr(),
                children: [
                  SettingsCategory(
                    title: LocaleKeys.settings_billingPage_plan_title.tr(),
                    children: [
                      SingleSettingAction(
                        onPressed: () => _openPricingDialog(
                          context,
                          workspaceId,
                          state.subscription.subscriptionPlan,
                        ),
                        label: state.subscription.label,
                        buttonLabel: LocaleKeys
                            .settings_billingPage_plan_planButtonLabel
                            .tr(),
                      ),
                      SingleSettingAction(
                        onPressed: () =>
                            afLaunchUrlString(state.billingPortal!.url),
                        label: LocaleKeys
                            .settings_billingPage_plan_billingPeriod
                            .tr(),
                        buttonLabel: LocaleKeys
                            .settings_billingPage_plan_periodButtonLabel
                            .tr(),
                      ),
                    ],
                  ),
                  SettingsCategory(
                    title: LocaleKeys.settings_billingPage_paymentDetails_title
                        .tr(),
                    children: [
                      SingleSettingAction(
                        onPressed: () =>
                            afLaunchUrlString(state.billingPortal!.url),
                        label: LocaleKeys
                            .settings_billingPage_paymentDetails_methodLabel
                            .tr(),
                        buttonLabel: LocaleKeys
                            .settings_billingPage_paymentDetails_methodButtonLabel
                            .tr(),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openPricingDialog(
    BuildContext context,
    String workspaceId,
    SubscriptionPlanPB plan,
  ) =>
      showDialog(
        context: context,
        builder: (_) => BlocProvider<SettingsPlanBloc>(
          create: (_) => SettingsPlanBloc(workspaceId: workspaceId)
            ..add(const SettingsPlanEvent.started()),
          child: SettingsPlanComparisonDialog(
            workspaceId: workspaceId,
            currentPlan: plan,
          ),
        ),
      );
}
