import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_usage_ext.dart';
import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/flowy_gradient_button.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
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
            ready: (state) {
              return SettingsBody(
                autoSeparate: false,
                title: LocaleKeys.settings_planPage_title.tr(),
                children: [
                  _PlanUsageSummary(
                    usage: state.workspaceUsage,
                    subscription: state.subscription,
                  ),
                  _CurrentPlanBox(subscription: state.subscription),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CurrentPlanBox extends StatelessWidget {
  const _CurrentPlanBox({required this.subscription});

  final WorkspaceSubscriptionPB subscription;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlowyText.semibold(
                      subscription.label,
                      fontSize: 24,
                    ),
                    const VSpace(4),
                    FlowyText.regular(
                      LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeInfo
                          .tr(),
                      fontSize: 16,
                      maxLines: 3,
                    ),
                    const VSpace(16),
                    FlowyGradientButton(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_upgrade
                          .tr(),
                      onPressed: () => _openPricingDialog(
                        context,
                        context.read<SettingsPlanBloc>().workspaceId,
                        subscription,
                      ),
                    ),
                    if (subscription.hasCanceled) ...[
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
              const HSpace(16),
              Expanded(
                child: SeparatedColumn(
                  separatorBuilder: () => const VSpace(4),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._getPros(subscription.subscriptionPlan).map(
                      (s) => _ProConItem(label: s),
                    ),
                    ..._getCons(subscription.subscriptionPlan).map(
                      (s) => _ProConItem(label: s, isPro: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(color: Color(0xFF4F3F5F)),
            child: Center(
              child: FlowyText.semibold(
                LocaleKeys.settings_planPage_planUsage_currentPlan_bannerLabel
                    .tr(),
                fontSize: 16,
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
      subscription.canceledAt.toDateTime(),
      true,
      appearance.timeFormat,
    );
  }

  void _openPricingDialog(
    BuildContext context,
    String workspaceId,
    WorkspaceSubscriptionPB subscription,
  ) =>
      showDialog(
        context: context,
        builder: (_) => BlocProvider<SettingsPlanBloc>.value(
          value: context.read<SettingsPlanBloc>(),
          child: SettingsPlanComparisonDialog(
            workspaceId: workspaceId,
            subscription: subscription,
          ),
        ),
      );

  List<String> _getPros(SubscriptionPlanPB plan) => switch (plan) {
        SubscriptionPlanPB.Pro => _proPros(),
        _ => _freePros(),
      };

  List<String> _getCons(SubscriptionPlanPB plan) => switch (plan) {
        SubscriptionPlanPB.Pro => _proCons(),
        _ => _freeCons(),
      };

  List<String> _freePros() => [
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeProOne.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeProTwo.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeProThree.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeProFour.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeProFive.tr(),
      ];
  List<String> _freeCons() => [
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeConOne.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeConTwo.tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_freeConThree.tr(),
      ];

  List<String> _proPros() => [
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalProOne
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalProTwo
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalProThree
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalProFour
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalProFive
            .tr(),
      ];
  List<String> _proCons() => [
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalConOne
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalConTwo
            .tr(),
        LocaleKeys.settings_planPage_planUsage_currentPlan_professionalConThree
            .tr(),
      ];
}

class _ProConItem extends StatelessWidget {
  const _ProConItem({
    required this.label,
    this.isPro = true,
  });

  final String label;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: FlowySvg(
            isPro ? FlowySvgs.check_s : FlowySvgs.close_s,
            color: isPro ? null : const Color(0xFF900000),
          ),
        ),
        const HSpace(4),
        Flexible(
          child: FlowyText.regular(
            label,
            fontSize: 12,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _PlanUsageSummary extends StatelessWidget {
  const _PlanUsageSummary({required this.usage, required this.subscription});

  final WorkspaceUsagePB usage;
  final WorkspaceSubscriptionPB subscription;

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
                label: LocaleKeys.settings_planPage_planUsage_storageUsage.tr(
                  args: [
                    usage.currentBlobInGb,
                    usage.totalBlobInGb,
                  ],
                ),
                value: usage.totalBlobBytes.toInt() /
                    usage.totalBlobBytesLimit.toInt(),
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
            _ToggleMore(
              value: subscription.subscriptionPlan == SubscriptionPlanPB.Pro,
              label:
                  LocaleKeys.settings_planPage_planUsage_memberProToggle.tr(),
              subscription: subscription,
              badgeLabel: LocaleKeys.settings_planPage_planUsage_proBadge.tr(),
            ),
            const VSpace(8),
            _ToggleMore(
              value: subscription.subscriptionPlan == SubscriptionPlanPB.Pro,
              label:
                  LocaleKeys.settings_planPage_planUsage_guestCollabToggle.tr(),
              subscription: subscription,
              badgeLabel: LocaleKeys.settings_planPage_planUsage_proBadge.tr(),
            ),
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
  });

  final String title;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          title,
          fontSize: 11,
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
        _PlanProgressIndicator(label: label, progress: value),
      ],
    );
  }
}

class _ToggleMore extends StatefulWidget {
  const _ToggleMore({
    required this.value,
    required this.label,
    required this.subscription,
    this.badgeLabel,
  });

  final bool value;
  final String label;
  final WorkspaceSubscriptionPB subscription;
  final String? badgeLabel;

  @override
  State<_ToggleMore> createState() => _ToggleMoreState();
}

class _ToggleMoreState extends State<_ToggleMore> {
  late bool toggleValue = widget.value;

  @override
  Widget build(BuildContext context) {
    final isLM = Brightness.light == Theme.of(context).brightness;
    final primaryColor =
        isLM ? const Color(0xFF653E8C) : const Color(0xFFE8E2EE);
    final secondaryColor =
        isLM ? const Color(0xFFE8E2EE) : const Color(0xFF653E8C);

    return Row(
      children: [
        Toggle(
          value: toggleValue,
          padding: EdgeInsets.zero,
          style: ToggleStyle.big,
          onChanged: (_) {
            setState(() => toggleValue = !toggleValue);

            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider<SettingsPlanBloc>.value(
                    value: context.read<SettingsPlanBloc>(),
                    child: SettingsPlanComparisonDialog(
                      workspaceId: context.read<SettingsPlanBloc>().workspaceId,
                      subscription: widget.subscription,
                    ),
                  ),
                ).then((_) {
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      setState(() => toggleValue = !toggleValue);
                    }
                  });
                });
              }
            });
          },
        ),
        const HSpace(10),
        FlowyText.regular(widget.label, fontSize: 14),
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
