import 'package:flutter/material.dart';

import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/billing/settings_billing_bloc.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';

const _buttonsMinWidth = 100.0;

class SettingsBillingView extends StatelessWidget {
  const SettingsBillingView({
    super.key,
    required this.workspaceId,
    required this.user,
  });

  final String workspaceId;
  final UserProfilePB user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBillingBloc>(
      create: (_) => SettingsBillingBloc(
        workspaceId: workspaceId,
        userId: user.id,
      )..add(const SettingsBillingEvent.started()),
      child: BlocConsumer<SettingsBillingBloc, SettingsBillingState>(
        listener: (context, state) {},
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
              final billingPortalEnabled =
                  state.subscriptionInfo.plan != WorkspacePlanPB.FreePlan;

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
                          user.id,
                          state.subscriptionInfo,
                        ),
                        fontWeight: FontWeight.w500,
                        label: state.subscriptionInfo.label,
                        buttonLabel: LocaleKeys
                            .settings_billingPage_plan_planButtonLabel
                            .tr(),
                        minWidth: _buttonsMinWidth,
                      ),
                      if (billingPortalEnabled)
                        SingleSettingAction(
                          onPressed: () => context
                              .read<SettingsBillingBloc>()
                              .add(
                                const SettingsBillingEvent.openCustomerPortal(),
                              ),
                          label: LocaleKeys
                              .settings_billingPage_plan_billingPeriod
                              .tr(),
                          fontWeight: FontWeight.w500,
                          buttonLabel: LocaleKeys
                              .settings_billingPage_plan_periodButtonLabel
                              .tr(),
                          minWidth: _buttonsMinWidth,
                        ),
                    ],
                  ),
                  if (billingPortalEnabled)
                    SettingsCategory(
                      title: LocaleKeys
                          .settings_billingPage_paymentDetails_title
                          .tr(),
                      children: [
                        SingleSettingAction(
                          onPressed: () => context
                              .read<SettingsBillingBloc>()
                              .add(
                                const SettingsBillingEvent.openCustomerPortal(),
                              ),
                          label: LocaleKeys
                              .settings_billingPage_paymentDetails_methodLabel
                              .tr(),
                          fontWeight: FontWeight.w500,
                          buttonLabel: LocaleKeys
                              .settings_billingPage_paymentDetails_methodButtonLabel
                              .tr(),
                          minWidth: _buttonsMinWidth,
                        ),
                      ],
                    ),
                  SettingsCategory(
                    title: LocaleKeys.settings_billingPage_addons_title.tr(),
                    children: [
                      _AITile(
                        plan: SubscriptionPlanPB.AiMax,
                        label: LocaleKeys
                            .settings_billingPage_addons_aiMax_label
                            .tr(),
                        description: LocaleKeys
                            .settings_billingPage_addons_aiMax_description,
                        activeDescription: LocaleKeys
                            .settings_billingPage_addons_aiMax_activeDescription,
                        canceledDescription: LocaleKeys
                            .settings_billingPage_addons_aiMax_canceledDescription,
                        subscriptionInfo:
                            state.subscriptionInfo.addOns.firstWhereOrNull(
                          (a) => a.type == WorkspaceAddOnPBType.AddOnAiMax,
                        ),
                      ),
                      _AITile(
                        plan: SubscriptionPlanPB.AiLocal,
                        label: LocaleKeys
                            .settings_billingPage_addons_aiOnDevice_label
                            .tr(),
                        description: LocaleKeys
                            .settings_billingPage_addons_aiOnDevice_description,
                        activeDescription: LocaleKeys
                            .settings_billingPage_addons_aiOnDevice_activeDescription,
                        canceledDescription: LocaleKeys
                            .settings_billingPage_addons_aiOnDevice_canceledDescription,
                        subscriptionInfo:
                            state.subscriptionInfo.addOns.firstWhereOrNull(
                          (a) => a.type == WorkspaceAddOnPBType.AddOnAiLocal,
                        ),
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
    Int64 userId,
    WorkspaceSubscriptionInfoPB subscriptionInfo,
  ) =>
      showDialog<bool?>(
        context: context,
        builder: (_) => BlocProvider<SettingsPlanBloc>(
          create: (_) =>
              SettingsPlanBloc(workspaceId: workspaceId, userId: user.id)
                ..add(const SettingsPlanEvent.started()),
          child: SettingsPlanComparisonDialog(
            workspaceId: workspaceId,
            subscriptionInfo: subscriptionInfo,
          ),
        ),
      ).then((didChangePlan) {
        if (didChangePlan == true) {
          context
              .read<SettingsBillingBloc>()
              .add(const SettingsBillingEvent.started());
        }
      });
}

class _AITile extends StatelessWidget {
  const _AITile({
    required this.label,
    required this.description,
    required this.canceledDescription,
    required this.activeDescription,
    required this.plan,
    this.subscriptionInfo,
  });

  final String label;
  final String description;
  final String canceledDescription;
  final String activeDescription;
  final SubscriptionPlanPB plan;
  final WorkspaceAddOnPB? subscriptionInfo;

  @override
  Widget build(BuildContext context) {
    final isCanceled = subscriptionInfo?.addOnSubscription.status ==
        WorkspaceSubscriptionStatusPB.Canceled;

    final dateFormat = context.read<AppearanceSettingsCubit>().state.dateFormat;

    return SingleSettingAction(
      label: label,
      description: subscriptionInfo != null && isCanceled
          ? canceledDescription.tr(
              args: [
                dateFormat.formatDate(
                  subscriptionInfo!.addOnSubscription.endDate.toDateTime(),
                  false,
                ),
              ],
            )
          : subscriptionInfo != null
              ? activeDescription.tr(
                  args: [
                    dateFormat.formatDate(
                      subscriptionInfo!.addOnSubscription.endDate.toDateTime(),
                      false,
                    ),
                  ],
                )
              : description.tr(),
      buttonLabel: subscriptionInfo != null
          ? isCanceled
              ? LocaleKeys.settings_billingPage_addons_renewLabel.tr()
              : LocaleKeys.settings_billingPage_addons_removeLabel.tr()
          : LocaleKeys.settings_billingPage_addons_addLabel.tr(),
      fontWeight: FontWeight.w500,
      minWidth: _buttonsMinWidth,
      onPressed: () {
        if (subscriptionInfo != null && isCanceled) {
          // Show customer portal to renew
          context
              .read<SettingsBillingBloc>()
              .add(const SettingsBillingEvent.openCustomerPortal());
        } else if (subscriptionInfo != null) {
          SettingsAlertDialog(
            title: 'Remove AI Max',
            subtitle:
                'Are you sure you want to remove AI Max? You will keep the benefits until the end of the billing period.',
            confirm: () {
              Navigator.of(context).pop();
              context
                  .read<SettingsBillingBloc>()
                  .add(SettingsBillingEvent.cancelSubscription(plan));
            },
          ).show(context);
        } else {
          // Add the addon
          context
              .read<SettingsBillingBloc>()
              .add(SettingsBillingEvent.addSubscription(plan));
        }
      },
    );
  }
}
