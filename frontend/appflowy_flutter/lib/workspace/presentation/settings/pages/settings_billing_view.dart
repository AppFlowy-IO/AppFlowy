import 'package:flutter/material.dart';

import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/billing/settings_billing_bloc.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_dashed_divider.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';
import '../../../../plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';

const _buttonsMinWidth = 100.0;

class SettingsBillingView extends StatefulWidget {
  const SettingsBillingView({
    super.key,
    required this.workspaceId,
    required this.user,
  });

  final String workspaceId;
  final UserProfilePB user;

  @override
  State<SettingsBillingView> createState() => _SettingsBillingViewState();
}

class _SettingsBillingViewState extends State<SettingsBillingView> {
  Loading? loadingIndicator;
  RecurringIntervalPB? selectedInterval;
  final ValueNotifier<bool> enablePlanChangeNotifier = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBillingBloc>(
      create: (_) => SettingsBillingBloc(
        workspaceId: widget.workspaceId,
        userId: widget.user.id,
      )..add(const SettingsBillingEvent.started()),
      child: BlocConsumer<SettingsBillingBloc, SettingsBillingState>(
        listenWhen: (previous, current) =>
            previous.mapOrNull(ready: (s) => s.isLoading) !=
            current.mapOrNull(ready: (s) => s.isLoading),
        listener: (context, state) {
          if (state.mapOrNull(ready: (s) => s.isLoading) == true) {
            loadingIndicator = Loading(context)..start();
          } else {
            loadingIndicator?.stop();
            loadingIndicator = null;
          }
        },
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
                          widget.workspaceId,
                          widget.user.id,
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
                          onPressed: () {
                            SettingsAlertDialog(
                              title: LocaleKeys
                                  .settings_billingPage_changePeriod
                                  .tr(),
                              enableConfirmNotifier: enablePlanChangeNotifier,
                              children: [
                                ChangePeriod(
                                  plan: state.subscriptionInfo.planSubscription
                                      .subscriptionPlan,
                                  selectedInterval: state.subscriptionInfo
                                      .planSubscription.interval,
                                  onSelected: (interval) {
                                    enablePlanChangeNotifier.value = interval !=
                                        state.subscriptionInfo.planSubscription
                                            .interval;
                                    selectedInterval = interval;
                                  },
                                ),
                              ],
                              confirm: () {
                                if (selectedInterval !=
                                    state.subscriptionInfo.planSubscription
                                        .interval) {
                                  context.read<SettingsBillingBloc>().add(
                                        SettingsBillingEvent.updatePeriod(
                                          plan: state
                                              .subscriptionInfo
                                              .planSubscription
                                              .subscriptionPlan,
                                          interval: selectedInterval!,
                                        ),
                                      );
                                }
                                Navigator.of(context).pop();
                              },
                            ).show(context);
                          },
                          label: LocaleKeys
                              .settings_billingPage_plan_billingPeriod
                              .tr(),
                          description: state
                              .subscriptionInfo.planSubscription.interval.label,
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
                      const SettingsDashedDivider(),
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
              SettingsPlanBloc(workspaceId: workspaceId, userId: widget.user.id)
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

class _AITile extends StatefulWidget {
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
  State<_AITile> createState() => _AITileState();
}

class _AITileState extends State<_AITile> {
  RecurringIntervalPB? selectedInterval;

  final enableConfirmNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    final isCanceled = widget.subscriptionInfo?.addOnSubscription.status ==
        WorkspaceSubscriptionStatusPB.Canceled;

    final dateFormat = context.read<AppearanceSettingsCubit>().state.dateFormat;

    return Column(
      children: [
        SingleSettingAction(
          label: widget.label,
          description: widget.subscriptionInfo != null && isCanceled
              ? widget.canceledDescription.tr(
                  args: [
                    dateFormat.formatDate(
                      widget.subscriptionInfo!.addOnSubscription.endDate
                          .toDateTime(),
                      false,
                    ),
                  ],
                )
              : widget.subscriptionInfo != null
                  ? widget.activeDescription.tr(
                      args: [
                        dateFormat.formatDate(
                          widget.subscriptionInfo!.addOnSubscription.endDate
                              .toDateTime(),
                          false,
                        ),
                      ],
                    )
                  : widget.description.tr(),
          buttonLabel: widget.subscriptionInfo != null
              ? isCanceled
                  ? LocaleKeys.settings_billingPage_addons_renewLabel.tr()
                  : LocaleKeys.settings_billingPage_addons_removeLabel.tr()
              : LocaleKeys.settings_billingPage_addons_addLabel.tr(),
          fontWeight: FontWeight.w500,
          minWidth: _buttonsMinWidth,
          onPressed: () {
            if (widget.subscriptionInfo != null && isCanceled) {
              // Show customer portal to renew
              context
                  .read<SettingsBillingBloc>()
                  .add(const SettingsBillingEvent.openCustomerPortal());
            } else if (widget.subscriptionInfo != null) {
              showConfirmDialog(
                context: context,
                style: ConfirmPopupStyle.cancelAndOk,
                title: LocaleKeys.settings_billingPage_addons_removeDialog_title
                    .tr(args: [widget.plan.label]).tr(),
                description: LocaleKeys
                    .settings_billingPage_addons_removeDialog_description
                    .tr(namedArgs: {"plan": widget.plan.label.tr()}),
                confirmLabel: LocaleKeys.button_confirm.tr(),
                onConfirm: () {
                  context.read<SettingsBillingBloc>().add(
                        SettingsBillingEvent.cancelSubscription(widget.plan),
                      );
                },
              );
            } else {
              // Add the addon
              context
                  .read<SettingsBillingBloc>()
                  .add(SettingsBillingEvent.addSubscription(widget.plan));
            }
          },
        ),
        if (widget.subscriptionInfo != null) ...[
          const VSpace(10),
          SingleSettingAction(
            label: LocaleKeys.settings_billingPage_planPeriod.tr(
              args: [
                widget
                    .subscriptionInfo!.addOnSubscription.subscriptionPlan.label,
              ],
            ),
            description:
                widget.subscriptionInfo!.addOnSubscription.interval.label,
            buttonLabel:
                LocaleKeys.settings_billingPage_plan_periodButtonLabel.tr(),
            minWidth: _buttonsMinWidth,
            onPressed: () {
              enableConfirmNotifier.value = false;
              SettingsAlertDialog(
                title: LocaleKeys.settings_billingPage_changePeriod.tr(),
                enableConfirmNotifier: enableConfirmNotifier,
                children: [
                  ChangePeriod(
                    plan: widget
                        .subscriptionInfo!.addOnSubscription.subscriptionPlan,
                    selectedInterval:
                        widget.subscriptionInfo!.addOnSubscription.interval,
                    onSelected: (interval) {
                      enableConfirmNotifier.value = interval !=
                          widget.subscriptionInfo!.addOnSubscription.interval;
                      selectedInterval = interval;
                    },
                  ),
                ],
                confirm: () {
                  if (selectedInterval !=
                      widget.subscriptionInfo!.addOnSubscription.interval) {
                    context.read<SettingsBillingBloc>().add(
                          SettingsBillingEvent.updatePeriod(
                            plan: widget.subscriptionInfo!.addOnSubscription
                                .subscriptionPlan,
                            interval: selectedInterval!,
                          ),
                        );
                  }
                  Navigator.of(context).pop();
                },
              ).show(context);
            },
          ),
        ],
      ],
    );
  }
}

class ChangePeriod extends StatefulWidget {
  const ChangePeriod({
    super.key,
    required this.plan,
    required this.selectedInterval,
    required this.onSelected,
  });

  final SubscriptionPlanPB plan;
  final RecurringIntervalPB selectedInterval;
  final Function(RecurringIntervalPB interval) onSelected;

  @override
  State<ChangePeriod> createState() => _ChangePeriodState();
}

class _ChangePeriodState extends State<ChangePeriod> {
  RecurringIntervalPB? _selectedInterval;

  @override
  void initState() {
    super.initState();
    _selectedInterval = widget.selectedInterval;
  }

  @override
  void didChangeDependencies() {
    _selectedInterval = widget.selectedInterval;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PeriodSelector(
          price: widget.plan.priceMonthBilling,
          interval: RecurringIntervalPB.Month,
          isSelected: _selectedInterval == RecurringIntervalPB.Month,
          isCurrent: widget.selectedInterval == RecurringIntervalPB.Month,
          onSelected: () {
            widget.onSelected(RecurringIntervalPB.Month);
            setState(
              () => _selectedInterval = RecurringIntervalPB.Month,
            );
          },
        ),
        const VSpace(16),
        _PeriodSelector(
          price: widget.plan.priceAnnualBilling,
          interval: RecurringIntervalPB.Year,
          isSelected: _selectedInterval == RecurringIntervalPB.Year,
          isCurrent: widget.selectedInterval == RecurringIntervalPB.Year,
          onSelected: () {
            widget.onSelected(RecurringIntervalPB.Year);
            setState(
              () => _selectedInterval = RecurringIntervalPB.Year,
            );
          },
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.price,
    required this.interval,
    required this.onSelected,
    required this.isSelected,
    required this.isCurrent,
  });

  final String price;
  final RecurringIntervalPB interval;
  final VoidCallback onSelected;
  final bool isSelected;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isCurrent && !isSelected ? 0.7 : 1,
      child: GestureDetector(
        onTap: isCurrent ? null : onSelected,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FlowyText(
                          interval.label,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        if (isCurrent) ...[
                          const HSpace(8),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              child: FlowyText(
                                LocaleKeys
                                    .settings_billingPage_currentPeriodBadge
                                    .tr(),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const VSpace(8),
                    FlowyText(
                      price,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    const VSpace(4),
                    FlowyText(
                      interval.priceInfo,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ],
                ),
                const Spacer(),
                if (!isCurrent && !isSelected || isSelected) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 1.5,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: Center(
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
