import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPlanComparisonDialog extends StatefulWidget {
  const SettingsPlanComparisonDialog({
    super.key,
    required this.workspaceId,
    required this.currentPlan,
  });

  final String workspaceId;
  final SubscriptionPlanPB currentPlan;

  @override
  State<SettingsPlanComparisonDialog> createState() =>
      _SettingsPlanComparisonDialogState();
}

class _SettingsPlanComparisonDialogState
    extends State<SettingsPlanComparisonDialog> {
  final horizontalController = ScrollController();
  final verticalController = ScrollController();

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      constraints: const BoxConstraints(maxWidth: 784, minWidth: 674),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlowyText.semibold(
                  'Compare & select plan',
                  fontSize: 24,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: Navigator.of(context).pop,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: FlowySvg(
                      FlowySvgs.m_close_m,
                      size: const Size.square(20),
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                controller: verticalController,
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VSpace(18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 248,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const VSpace(22),
                              const SizedBox(
                                height: 100,
                                child: FlowyText.semibold(
                                  'Plan\nFeatures',
                                  fontSize: 24,
                                  maxLines: 2,
                                  color: Color(0xFF5C3699),
                                ),
                              ),
                              const SizedBox(height: 64),
                              const SizedBox(height: 56),
                              ..._planLabels.map(
                                (e) => _ComparisonCell(
                                  label: e.label,
                                  tooltip: e.tooltip,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PlanTable(
                          title: LocaleKeys
                              .settings_comparePlanDialog_freePlan_title
                              .tr(),
                          description: LocaleKeys
                              .settings_comparePlanDialog_freePlan_description
                              .tr(),
                          price: LocaleKeys
                              .settings_comparePlanDialog_freePlan_price
                              .tr(),
                          priceInfo: LocaleKeys
                              .settings_comparePlanDialog_freePlan_priceInfo
                              .tr(),
                          cells: _freeLabels,
                          isCurrent:
                              widget.currentPlan == SubscriptionPlanPB.None,
                          canDowngrade:
                              widget.currentPlan != SubscriptionPlanPB.None,
                          onSelected: () async {
                            if (widget.currentPlan == SubscriptionPlanPB.None) {
                              return;
                            }

                            context.read<SettingsPlanBloc>().add(
                                  const SettingsPlanEvent.cancelSubscription(),
                                );
                          },
                        ),
                        _PlanTable(
                          title: LocaleKeys
                              .settings_comparePlanDialog_proPlan_title
                              .tr(),
                          description: LocaleKeys
                              .settings_comparePlanDialog_proPlan_description
                              .tr(),
                          price: LocaleKeys
                              .settings_comparePlanDialog_proPlan_price
                              .tr(),
                          priceInfo: LocaleKeys
                              .settings_comparePlanDialog_proPlan_priceInfo
                              .tr(),
                          cells: _proLabels,
                          isCurrent:
                              widget.currentPlan == SubscriptionPlanPB.Pro,
                          canUpgrade:
                              widget.currentPlan == SubscriptionPlanPB.None,
                          onSelected: () =>
                              context.read<SettingsPlanBloc>().add(
                                    const SettingsPlanEvent.addSubscription(
                                      SubscriptionPlanPB.Pro,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTable extends StatelessWidget {
  const _PlanTable({
    required this.title,
    required this.description,
    required this.price,
    required this.priceInfo,
    required this.cells,
    required this.isCurrent,
    required this.onSelected,
    this.canUpgrade = false,
    this.canDowngrade = false,
  });

  final String title;
  final String description;
  final String price;
  final String priceInfo;

  final List<String> cells;
  final bool isCurrent;
  final VoidCallback onSelected;
  final bool canUpgrade;
  final bool canDowngrade;

  @override
  Widget build(BuildContext context) {
    final highlightPlan = !isCurrent && !canDowngrade && canUpgrade;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: !highlightPlan
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF251D37),
                  Color(0xFF7547C0),
                ],
              ),
      ),
      padding: !highlightPlan
          ? const EdgeInsets.only(top: 4)
          : const EdgeInsets.all(4),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Heading(
              title: title,
              description: description,
              isPrimary: !highlightPlan,
              horizontalInset: 12,
            ),
            _Heading(
              title: price,
              description: priceInfo,
              isPrimary: !highlightPlan,
              height: 64,
              horizontalInset: 12,
            ),
            if (canUpgrade || canDowngrade) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _ActionButton(
                  onPressed: onSelected,
                  isUpgrade: canUpgrade && !canDowngrade,
                  useGradientBorder: !isCurrent && canUpgrade,
                ),
              ),
            ] else ...[
              const SizedBox(height: 56),
            ],
            ...cells.map((e) => _ComparisonCell(label: e)),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCell extends StatelessWidget {
  const _ComparisonCell({required this.label, this.tooltip});

  final String label;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText.medium(label),
          const Spacer(),
          if (tooltip != null)
            FlowyTooltip(
              message: tooltip,
              child: const FlowySvg(FlowySvgs.information_s),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.isUpgrade,
    this.useGradientBorder = false,
  });

  final VoidCallback onPressed;
  final bool isUpgrade;
  final bool useGradientBorder;

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).brightness == Brightness.light;

    final gradientBorder = useGradientBorder && isLM;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _drawGradientBorder(
                isLM: isLM,
                child: Container(
                  height: gradientBorder ? 36 : 40,
                  width: gradientBorder ? 148 : 152,
                  decoration: BoxDecoration(
                    color: gradientBorder
                        ? Theme.of(context).cardColor
                        : Colors.transparent,
                    border: Border.all(
                      color: gradientBorder
                          ? Colors.transparent
                          : AFThemeExtension.of(context).textColor,
                    ),
                    borderRadius:
                        BorderRadius.circular(gradientBorder ? 14 : 16),
                  ),
                  child: Center(
                    child: _drawText(
                      isUpgrade
                          ? LocaleKeys
                              .settings_comparePlanDialog_actions_upgrade
                              .tr()
                          : LocaleKeys
                              .settings_comparePlanDialog_actions_downgrade
                              .tr(),
                      isLM,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawText(String text, bool isLM) {
    final child = FlowyText(
      text,
      fontSize: 14,
      fontWeight: useGradientBorder ? FontWeight.w600 : FontWeight.w500,
    );

    if (!useGradientBorder || !isLM) {
      return child;
    }

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        transform: GradientRotation(-1.55),
        stops: [0.4, 1],
        colors: [
          Color(0xFF251D37),
          Color(0xFF7547C0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: child,
    );
  }

  Widget _drawGradientBorder({required bool isLM, required Widget child}) {
    if (!useGradientBorder || !isLM) {
      return child;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          transform: GradientRotation(-1.2),
          stops: [0.4, 1],
          colors: [
            Color(0xFF251D37),
            Color(0xFF7547C0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    this.description,
    this.isPrimary = true,
    this.height = 100,
    this.horizontalInset = 0,
  });

  final String title;
  final String? description;
  final bool isPrimary;
  final double height;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(left: horizontalInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText.semibold(
              title,
              fontSize: 24,
              color: isPrimary ? null : const Color(0xFF5C3699),
            ),
            if (description != null && description!.isNotEmpty) ...[
              const VSpace(4),
              FlowyText.regular(
                description!,
                fontSize: 12,
                maxLines: 3,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanItem {
  const _PlanItem({required this.label, this.tooltip});

  final String label;
  final String? tooltip;
}

final _planLabels = [
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemOne.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemTwo.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemThree.tr(),
    tooltip: LocaleKeys.settings_comparePlanDialog_planLabels_tooltipThree.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemFour.tr(),
    tooltip: LocaleKeys.settings_comparePlanDialog_planLabels_tooltipFour.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemFive.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemSix.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemSeven.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemEight.tr(),
    tooltip: LocaleKeys.settings_comparePlanDialog_planLabels_tooltipEight.tr(),
  ),
];

final _freeLabels = [
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemOne.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemTwo.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemThree.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemFour.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemFive.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemSix.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemSeven.tr(),
  LocaleKeys.settings_comparePlanDialog_freeLabels_itemEight.tr(),
];

final _proLabels = [
  LocaleKeys.settings_comparePlanDialog_proLabels_itemOne.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemTwo.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemThree.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemFour.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemFive.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemSix.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemSeven.tr(),
  LocaleKeys.settings_comparePlanDialog_proLabels_itemEight.tr(),
];
