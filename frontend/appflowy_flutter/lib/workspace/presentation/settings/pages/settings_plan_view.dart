import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_usage_ext.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/flowy_gradient_button.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPlanView extends StatelessWidget {
  const SettingsPlanView({
    super.key,
    required this.workspaceId,
    required this.user,
  });

  final String workspaceId;
  final UserProfilePB user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsPlanBloc>(
      create: (context) => SettingsPlanBloc(
        workspaceId: workspaceId,
        userId: user.id,
      )..add(const SettingsPlanEvent.started()),
      child: BlocBuilder<SettingsPlanBloc, SettingsPlanState>(
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
            ready: (state) => SettingsBody(
              autoSeparate: false,
              title: LocaleKeys.settings_planPage_title.tr(),
              children: [
                _PlanUsageSummary(
                  usage: state.workspaceUsage,
                  subscriptionInfo: state.subscriptionInfo,
                ),
                const VSpace(16),
                _CurrentPlanBox(subscriptionInfo: state.subscriptionInfo),
                const VSpace(16),
                // TODO(Mathias): Localize and add business logic
                FlowyText(
                  LocaleKeys.settings_planPage_planUsage_addons_title.tr(),
                  fontSize: 18,
                  color: AFThemeExtension.of(context).strongText,
                  fontWeight: FontWeight.w600,
                ),
                const VSpace(8),
                Row(
                  children: [
                    Flexible(
                      child: _AddOnBox(
                        title: LocaleKeys
                            .settings_planPage_planUsage_addons_aiMax_title
                            .tr(),
                        description: LocaleKeys
                            .settings_planPage_planUsage_addons_aiMax_description
                            .tr(),
                        price: LocaleKeys
                            .settings_planPage_planUsage_addons_aiMax_price
                            .tr(args: ['\$8']),
                        priceInfo: LocaleKeys
                            .settings_planPage_planUsage_addons_aiMax_priceInfo
                            .tr(),
                        billingInfo: LocaleKeys
                            .settings_planPage_planUsage_addons_aiMax_billingInfo
                            .tr(args: ['\$10']),
                        buttonText: state.subscriptionInfo.hasAIMax
                            ? LocaleKeys
                                .settings_planPage_planUsage_addons_activeLabel
                                .tr()
                            : LocaleKeys
                                .settings_planPage_planUsage_addons_addLabel
                                .tr(),
                        isActive: state.subscriptionInfo.hasAIMax,
                      ),
                    ),
                    const HSpace(8),
                    Flexible(
                      child: _AddOnBox(
                        title: LocaleKeys
                            .settings_planPage_planUsage_addons_aiOnDevice_title
                            .tr(),
                        description: LocaleKeys
                            .settings_planPage_planUsage_addons_aiOnDevice_description
                            .tr(),
                        price: LocaleKeys
                            .settings_planPage_planUsage_addons_aiOnDevice_price
                            .tr(args: ['\$8']),
                        priceInfo: LocaleKeys
                            .settings_planPage_planUsage_addons_aiOnDevice_priceInfo
                            .tr(),
                        billingInfo: LocaleKeys
                            .settings_planPage_planUsage_addons_aiOnDevice_billingInfo
                            .tr(args: ['\$10']),
                        buttonText: state.subscriptionInfo.hasAIOnDevice
                            ? LocaleKeys
                                .settings_planPage_planUsage_addons_activeLabel
                                .tr()
                            : LocaleKeys
                                .settings_planPage_planUsage_addons_addLabel
                                .tr(),
                        isActive: state.subscriptionInfo.hasAIOnDevice,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CurrentPlanBox extends StatefulWidget {
  const _CurrentPlanBox({required this.subscriptionInfo});

  final WorkspaceSubscriptionInfoPB subscriptionInfo;

  @override
  State<_CurrentPlanBox> createState() => _CurrentPlanBoxState();
}

class _CurrentPlanBoxState extends State<_CurrentPlanBox> {
  late SettingsPlanBloc planBloc;

  @override
  void initState() {
    super.initState();
    planBloc = context.read<SettingsPlanBloc>();
  }

  @override
  void didChangeDependencies() {
    planBloc = context.read<SettingsPlanBloc>();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDBDBD)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VSpace(4),
                        FlowyText.semibold(
                          widget.subscriptionInfo.label,
                          fontSize: 24,
                          color: AFThemeExtension.of(context).strongText,
                        ),
                        const VSpace(8),
                        FlowyText.regular(
                          widget.subscriptionInfo.info,
                          fontSize: 16,
                          color: AFThemeExtension.of(context).strongText,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    flex: 5,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: FlowyGradientButton(
                            label: LocaleKeys
                                .settings_planPage_planUsage_currentPlan_upgrade
                                .tr(),
                            onPressed: () => _openPricingDialog(
                              context,
                              context.read<SettingsPlanBloc>().workspaceId,
                              widget.subscriptionInfo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.subscriptionInfo.isCanceled) ...[
                const VSpace(12),
                FlowyText(
                  LocaleKeys
                      .settings_planPage_planUsage_currentPlan_canceledInfo
                      .tr(
                    args: [_canceledDate(context)],
                  ),
                  maxLines: 5,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFF4F3F5F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Center(
              child: FlowyText.semibold(
                LocaleKeys.settings_planPage_planUsage_currentPlan_bannerLabel
                    .tr(),
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _canceledDate(BuildContext context) {
    final appearance = context.read<AppearanceSettingsCubit>().state;
    return appearance.dateFormat.formatDate(
      widget.subscriptionInfo.planSubscription.endDate.toDateTime(),
      false,
    );
  }

  void _openPricingDialog(
    BuildContext context,
    String workspaceId,
    WorkspaceSubscriptionInfoPB subscriptionInfo,
  ) =>
      showDialog(
        context: context,
        builder: (_) => BlocProvider<SettingsPlanBloc>.value(
          value: planBloc,
          child: SettingsPlanComparisonDialog(
            workspaceId: workspaceId,
            subscriptionInfo: subscriptionInfo,
          ),
        ),
      );
}

class _PlanUsageSummary extends StatelessWidget {
  const _PlanUsageSummary({
    required this.usage,
    required this.subscriptionInfo,
  });

  final WorkspaceUsagePB usage;
  final WorkspaceSubscriptionInfoPB subscriptionInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.semibold(
          LocaleKeys.settings_planPage_planUsage_title.tr(),
          maxLines: 2,
          fontSize: 16,
          overflow: TextOverflow.ellipsis,
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
        const VSpace(16),
        Row(
          children: [
            Expanded(
              child: _UsageBox(
                title: LocaleKeys.settings_planPage_planUsage_storageLabel.tr(),
                replacementText: subscriptionInfo.plan ==
                        WorkspacePlanPB.ProPlan
                    ? LocaleKeys.settings_planPage_planUsage_storageUnlimited
                        .tr()
                    : null,
                label: LocaleKeys.settings_planPage_planUsage_storageUsage.tr(
                  args: [
                    usage.currentBlobInGb,
                    usage.totalBlobInGb,
                  ],
                ),
                value: usage.storageBytes.toInt() /
                    usage.storageBytesLimit.toInt(),
              ),
            ),
            Expanded(
              child: _UsageBox(
                title: LocaleKeys.settings_planPage_planUsage_collaboratorsLabel
                    .tr(),
                label: LocaleKeys.settings_planPage_planUsage_collaboratorsUsage
                    .tr(
                  args: [
                    usage.memberCount.toString(),
                    usage.memberCountLimit.toString(),
                  ],
                ),
                value:
                    usage.memberCount.toInt() / usage.memberCountLimit.toInt(),
              ),
            ),
          ],
        ),
        const VSpace(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subscriptionInfo.plan == WorkspacePlanPB.FreePlan) ...[
              _ToggleMore(
                value: false,
                label:
                    LocaleKeys.settings_planPage_planUsage_memberProToggle.tr(),
                badgeLabel:
                    LocaleKeys.settings_planPage_planUsage_proBadge.tr(),
                onTap: () async {
                  context.read<SettingsPlanBloc>().add(
                        const SettingsPlanEvent.addSubscription(
                          SubscriptionPlanPB.Pro,
                        ),
                      );
                  await Future.delayed(
                    const Duration(seconds: 2),
                    () {},
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _UsageBox extends StatelessWidget {
  const _UsageBox({
    required this.title,
    required this.label,
    required this.value,
    this.replacementText,
  });

  final String title;
  final String label;
  final double value;

  /// Replaces the progress indicator if not null
  final String? replacementText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.medium(
          title,
          fontSize: 11,
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
        if (replacementText != null) ...[
          Row(
            children: [
              Flexible(
                child: FlowyText.medium(
                  replacementText!,
                  fontSize: 11,
                  color: AFThemeExtension.of(context).secondaryTextColor,
                ),
              ),
            ],
          ),
        ] else ...[
          _PlanProgressIndicator(label: label, progress: value),
        ],
      ],
    );
  }
}

class _ToggleMore extends StatefulWidget {
  const _ToggleMore({
    required this.value,
    required this.label,
    this.badgeLabel,
    this.onTap,
  });

  final bool value;
  final String label;
  final String? badgeLabel;
  final Future<void> Function()? onTap;

  @override
  State<_ToggleMore> createState() => _ToggleMoreState();
}

class _ToggleMoreState extends State<_ToggleMore> {
  late bool toggleValue = widget.value;

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).isLightMode;
    final primaryColor =
        isLM ? const Color(0xFF653E8C) : const Color(0xFFE8E2EE);
    final secondaryColor =
        isLM ? const Color(0xFFE8E2EE) : const Color(0xFF653E8C);

    return Row(
      children: [
        Toggle(
          value: toggleValue,
          padding: EdgeInsets.zero,
          onChanged: (_) async {
            if (widget.onTap == null || toggleValue) {
              return;
            }

            setState(() => toggleValue = !toggleValue);
            await widget.onTap!();

            if (mounted) {
              setState(() => toggleValue = !toggleValue);
            }
          },
        ),
        const HSpace(10),
        FlowyText.regular(
          widget.label,
          fontSize: 14,
          color: AFThemeExtension.of(context).strongText,
        ),
        if (widget.badgeLabel != null && widget.badgeLabel!.isNotEmpty) ...[
          const HSpace(10),
          SizedBox(
            height: 26,
            child: Badge(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: secondaryColor,
              label: FlowyText.semibold(
                widget.badgeLabel!,
                fontSize: 12,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanProgressIndicator extends StatelessWidget {
  const _PlanProgressIndicator({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AFThemeExtension.of(context).progressBarBGColor,
              border: Border.all(
                color: const Color(0xFFDDF1F7).withOpacity(
                  theme.brightness == Brightness.light ? 1 : 0.1,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const HSpace(8),
        FlowyText.medium(
          label,
          fontSize: 11,
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
        const HSpace(16),
      ],
    );
  }
}

class _AddOnBox extends StatelessWidget {
  const _AddOnBox({
    required this.title,
    required this.description,
    required this.price,
    required this.priceInfo,
    required this.billingInfo,
    required this.buttonText,
    required this.isActive,
  });

  final String title;
  final String description;
  final String price;
  final String priceInfo;
  final String billingInfo;
  final String buttonText;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive ? const Color(0xFF9C00FB) : const Color(0xFFBDBDBD),
        ),
        color: isActive
            ? const Color(0xFFF7F8FC).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText.semibold(
            title,
            fontSize: 14,
            color: AFThemeExtension.of(context).secondaryTextColor,
          ),
          const VSpace(4),
          FlowyText.regular(
            description,
            fontSize: 11,
            color: AFThemeExtension.of(context).strongText,
            maxLines: 4,
          ),
          const VSpace(4),
          FlowyText(
            price,
            fontSize: 24,
            color: AFThemeExtension.of(context).strongText,
          ),
          FlowyText(
            priceInfo,
            fontSize: 11,
            color: AFThemeExtension.of(context).strongText,
          ),
          const VSpace(6),
          Row(
            children: [
              Expanded(
                child: FlowyText(
                  billingInfo,
                  color: AFThemeExtension.of(context).secondaryTextColor,
                  fontSize: 11,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FlowyTextButton(
                  buttonText,
                  mainAxisAlignment: MainAxisAlignment.center,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  fillColor:
                      isActive ? const Color(0xFFE8E2EE) : Colors.transparent,
                  constraints: const BoxConstraints(minWidth: 115),
                  radius: Corners.s16Border,
                  hoverColor: isActive
                      ? const Color(0xFFE8E2EE)
                      : const Color(0xFF5C3699),
                  fontColor: const Color(0xFF5C3699),
                  fontHoverColor:
                      isActive ? const Color(0xFF5C3699) : Colors.white,
                  borderColor: isActive
                      ? const Color(0xFFE8E2EE)
                      : const Color(0xFF5C3699),
                  fontSize: 12,
                  onPressed: isActive ? null : () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uncomment if we need it in the future
// class _DealBox extends StatelessWidget {
//   const _DealBox();

//   @override
//   Widget build(BuildContext context) {
//     final isLM = Theme.of(context).brightness == Brightness.light;

//     return Container(
//       clipBehavior: Clip.antiAlias,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           stops: isLM ? null : [.2, .3, .6],
//           transform: isLM ? null : const GradientRotation(-.9),
//           begin: isLM ? Alignment.centerLeft : Alignment.topRight,
//           end: isLM ? Alignment.centerRight : Alignment.bottomLeft,
//           colors: [
//             isLM
//                 ? const Color(0xFF7547C0).withAlpha(60)
//                 : const Color(0xFF7547C0),
//             if (!isLM) const Color.fromARGB(255, 94, 57, 153),
//             isLM
//                 ? const Color(0xFF251D37).withAlpha(60)
//                 : const Color(0xFF251D37),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const VSpace(18),
//                       FlowyText.semibold(
//                         LocaleKeys.settings_planPage_planUsage_deal_title.tr(),
//                         fontSize: 24,
//                         color: Theme.of(context).colorScheme.tertiary,
//                       ),
//                       const VSpace(8),
//                       FlowyText.medium(
//                         LocaleKeys.settings_planPage_planUsage_deal_info.tr(),
//                         maxLines: 6,
//                         color: Theme.of(context).colorScheme.tertiary,
//                       ),
//                       const VSpace(8),
//                       FlowyGradientButton(
//                         label: LocaleKeys
//                             .settings_planPage_planUsage_deal_viewPlans
//                             .tr(),
//                         fontWeight: FontWeight.w500,
//                         backgroundColor: isLM ? null : Colors.white,
//                         textColor: isLM
//                             ? Colors.white
//                             : Theme.of(context).colorScheme.onPrimary,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Positioned(
//             right: 0,
//             top: 9,
//             child: Container(
//               height: 32,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   transform: const GradientRotation(.7),
//                   colors: [
//                     if (isLM) const Color(0xFF7156DF),
//                     isLM
//                         ? const Color(0xFF3B2E8A)
//                         : const Color(0xFFCE006F).withAlpha(150),
//                     isLM ? const Color(0xFF261A48) : const Color(0xFF431459),
//                   ],
//                 ),
//               ),
//               child: Center(
//                 child: FlowyText.semibold(
//                   LocaleKeys.settings_planPage_planUsage_deal_bannerLabel.tr(),
//                   fontSize: 16,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

/// Uncomment if we need it in the future
// class _AddAICreditBox extends StatelessWidget {
//   const _AddAICreditBox();

//   @override
//   Widget build(BuildContext context) {
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         border: Border.all(color: const Color(0xFFBDBDBD)),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FlowyText.semibold(
//               LocaleKeys.settings_planPage_planUsage_aiCredit_title.tr(),
//               fontSize: 18,
//               color: AFThemeExtension.of(context).secondaryTextColor,
//             ),
//             const VSpace(8),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Flexible(
//                   flex: 5,
//                   child: ConstrainedBox(
//                     constraints: const BoxConstraints(maxWidth: 180),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         FlowyText.semibold(
//                           LocaleKeys.settings_planPage_planUsage_aiCredit_price
//                               .tr(),
//                           fontSize: 24,
//                         ),
//                         FlowyText.medium(
//                           LocaleKeys
//                               .settings_planPage_planUsage_aiCredit_priceDescription
//                               .tr(),
//                           fontSize: 14,
//                           color:
//                               AFThemeExtension.of(context).secondaryTextColor,
//                         ),
//                         const VSpace(8),
//                         FlowyGradientButton(
//                           label: LocaleKeys
//                               .settings_planPage_planUsage_aiCredit_purchase
//                               .tr(),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const HSpace(16),
//                 Flexible(
//                   flex: 6,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       FlowyText.regular(
//                         LocaleKeys.settings_planPage_planUsage_aiCredit_info
//                             .tr(),
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 5,
//                       ),
//                       const VSpace(8),
//                       SeparatedColumn(
//                         separatorBuilder: () => const VSpace(4),
//                         children: [
//                           _AIStarItem(
//                             label: LocaleKeys
//                                 .settings_planPage_planUsage_aiCredit_infoItemOne
//                                 .tr(),
//                           ),
//                           _AIStarItem(
//                             label: LocaleKeys
//                                 .settings_planPage_planUsage_aiCredit_infoItemTwo
//                                 .tr(),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

/// Uncomment if we need it in the future
// class _AIStarItem extends StatelessWidget {
//   const _AIStarItem({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         const FlowySvg(FlowySvgs.ai_star_s, color: Color(0xFF750D7E)),
//         const HSpace(4),
//         Expanded(child: FlowyText(label, maxLines: 2)),
//       ],
//     );
//   }
// }
