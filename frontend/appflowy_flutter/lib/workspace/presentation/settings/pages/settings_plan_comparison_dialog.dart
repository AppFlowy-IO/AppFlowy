import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/application/settings/plan/settings_plan_bloc.dart';
import 'package:appflowy/workspace/application/settings/plan/workspace_subscription_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/locale_keys.g.dart';

class SettingsPlanComparisonDialog extends StatefulWidget {
  const SettingsPlanComparisonDialog({
    super.key,
    required this.workspaceId,
    required this.subscriptionInfo,
  });

  final String workspaceId;
  final WorkspaceSubscriptionInfoPB subscriptionInfo;

  @override
  State<SettingsPlanComparisonDialog> createState() =>
      _SettingsPlanComparisonDialogState();
}

class _SettingsPlanComparisonDialogState
    extends State<SettingsPlanComparisonDialog> {
  final horizontalController = ScrollController();
  final verticalController = ScrollController();

  late WorkspaceSubscriptionInfoPB currentInfo = widget.subscriptionInfo;

  @override
  void dispose() {
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).isLightMode;

    return BlocConsumer<SettingsPlanBloc, SettingsPlanState>(
      listener: (context, state) {
        final readyState = state.mapOrNull(ready: (state) => state);

        if (readyState == null) {
          return;
        }

        if (readyState.successfulPlanUpgrade != null) {
          showConfirmDialog(
            context: context,
            title: LocaleKeys.settings_comparePlanDialog_paymentSuccess_title
                .tr(args: [readyState.successfulPlanUpgrade!.label]),
            description: LocaleKeys
                .settings_comparePlanDialog_paymentSuccess_description
                .tr(args: [readyState.successfulPlanUpgrade!.label]),
            confirmLabel: LocaleKeys.button_close.tr(),
            onConfirm: () {},
          );
        }

        setState(() => currentInfo = readyState.subscriptionInfo);
      },
      builder: (context, state) => FlowyDialog(
        constraints: const BoxConstraints(maxWidth: 784, minWidth: 674),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlowyText.semibold(
                    LocaleKeys.settings_comparePlanDialog_title.tr(),
                    fontSize: 24,
                    color: AFThemeExtension.of(context).strongText,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(
                      currentInfo.plan != widget.subscriptionInfo.plan,
                    ),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: FlowySvg(
                        FlowySvgs.m_close_m,
                        size: const Size.square(20),
                        color: AFThemeExtension.of(context).strongText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const VSpace(16),
            Flexible(
              child: SingleChildScrollView(
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: verticalController,
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const VSpace(30),
                                SizedBox(
                                  height: 100,
                                  child: FlowyText.semibold(
                                    LocaleKeys
                                        .settings_comparePlanDialog_planFeatures
                                        .tr(),
                                    fontSize: 24,
                                    maxLines: 2,
                                    color: isLM
                                        ? const Color(0xFF5C3699)
                                        : const Color(0xFFE8E0FF),
                                  ),
                                ),
                                const SizedBox(height: 96),
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
                            // TODO(Mathias): the price should be dynamic based on the country and currency
                            price: LocaleKeys
                                .settings_comparePlanDialog_freePlan_price
                                .tr(args: ['US\$0']),
                            priceInfo: LocaleKeys
                                .settings_comparePlanDialog_freePlan_priceInfo
                                .tr(),
                            cells: _freeLabels,
                            isCurrent:
                                currentInfo.plan == WorkspacePlanPB.FreePlan,
                            canDowngrade:
                                currentInfo.plan != WorkspacePlanPB.FreePlan,
                            currentCanceled: currentInfo.isCanceled ||
                                (context
                                        .watch<SettingsPlanBloc>()
                                        .state
                                        .mapOrNull(
                                          loading: (_) => true,
                                          ready: (s) => s.downgradeProcessing,
                                        ) ??
                                    false),
                            onSelected: () async {
                              if (currentInfo.plan ==
                                      WorkspacePlanPB.FreePlan ||
                                  currentInfo.isCanceled) {
                                return;
                              }

                              await showConfirmDialog(
                                context: context,
                                title: LocaleKeys
                                    .settings_comparePlanDialog_downgradeDialog_title
                                    .tr(args: [currentInfo.label]),
                                description: LocaleKeys
                                    .settings_comparePlanDialog_downgradeDialog_description
                                    .tr(),
                                confirmLabel: LocaleKeys
                                    .settings_comparePlanDialog_downgradeDialog_downgradeLabel
                                    .tr(),
                                style: ConfirmPopupStyle.cancelAndOk,
                                onConfirm: () =>
                                    context.read<SettingsPlanBloc>().add(
                                          const SettingsPlanEvent
                                              .cancelSubscription(),
                                        ),
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
                            // TODO(Mathias): the price should be dynamic based on the country and currency
                            price: LocaleKeys
                                .settings_comparePlanDialog_proPlan_price
                                .tr(args: ['US\$10']),
                            priceInfo: LocaleKeys
                                .settings_comparePlanDialog_proPlan_priceInfo
                                .tr(args: ['US\$12.5']),
                            cells: _proLabels,
                            isCurrent:
                                currentInfo.plan == WorkspacePlanPB.ProPlan,
                            canUpgrade:
                                currentInfo.plan == WorkspacePlanPB.FreePlan,
                            currentCanceled: currentInfo.isCanceled,
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
    this.currentCanceled = false,
  });

  final String title;
  final String description;
  final String price;
  final String priceInfo;

  final List<_CellItem> cells;
  final bool isCurrent;
  final VoidCallback onSelected;
  final bool canUpgrade;
  final bool canDowngrade;
  final bool currentCanceled;

  @override
  Widget build(BuildContext context) {
    final highlightPlan = !isCurrent && !canDowngrade && canUpgrade;
    final isLM = Theme.of(context).isLightMode;

    return Container(
      width: 215,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: !highlightPlan
            ? null
            : LinearGradient(
                colors: [
                  isLM ? const Color(0xFF251D37) : const Color(0xFF7459AD),
                  isLM ? const Color(0xFF7547C0) : const Color(0xFFDDC8FF),
                ],
              ),
      ),
      padding: !highlightPlan
          ? const EdgeInsets.only(top: 4)
          : const EdgeInsets.all(4),
      child: Container(
        padding: isCurrent
            ? const EdgeInsets.only(bottom: 22)
            : const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCurrent) const _CurrentBadge(),
            const VSpace(4),
            _Heading(
              title: title,
              description: description,
              isPrimary: !highlightPlan,
            ),
            _Heading(
              title: price,
              description: priceInfo,
              isPrimary: !highlightPlan,
              height: 96,
            ),
            if (canUpgrade || canDowngrade) ...[
              Opacity(
                opacity: canDowngrade && currentCanceled ? 0.5 : 1,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 12 + (canUpgrade && !canDowngrade ? 12 : 0),
                  ),
                  child: _ActionButton(
                    label: canUpgrade && !canDowngrade
                        ? LocaleKeys.settings_comparePlanDialog_actions_upgrade
                            .tr()
                        : LocaleKeys
                            .settings_comparePlanDialog_actions_downgrade
                            .tr(),
                    onPressed: !canUpgrade && canDowngrade && currentCanceled
                        ? null
                        : onSelected,
                    tooltip: !canUpgrade && canDowngrade && currentCanceled
                        ? LocaleKeys
                            .settings_comparePlanDialog_actions_downgradeDisabledTooltip
                            .tr()
                        : null,
                    isUpgrade: canUpgrade && !canDowngrade,
                    useGradientBorder: !isCurrent && canUpgrade,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 56),
            ],
            ...cells.map(
              (cell) => _ComparisonCell(
                label: cell.label,
                icon: cell.icon,
                isHighlighted: highlightPlan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      height: 22,
      width: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).isLightMode
            ? const Color(0xFF4F3F5F)
            : const Color(0xFFE8E0FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: FlowyText.medium(
          LocaleKeys.settings_comparePlanDialog_current.tr(),
          fontSize: 12,
          color: Theme.of(context).isLightMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class _ComparisonCell extends StatelessWidget {
  const _ComparisonCell({
    required this.label,
    this.icon,
    this.tooltip,
    this.isHighlighted = false,
  });

  final String label;
  final FlowySvgData? icon;
  final String? tooltip;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12) +
          EdgeInsets.only(left: isHighlighted ? 12 : 0),
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            FlowySvg(
              icon!,
              color: AFThemeExtension.of(context).strongText,
            ),
          ] else ...[
            Expanded(
              child: FlowyText.medium(
                label,
                lineHeight: 1.2,
                color: AFThemeExtension.of(context).strongText,
              ),
            ),
          ],
          if (tooltip != null)
            FlowyTooltip(
              message: tooltip,
              child: FlowySvg(
                FlowySvgs.information_s,
                color: AFThemeExtension.of(context).strongText,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.tooltip,
    required this.onPressed,
    required this.isUpgrade,
    this.useGradientBorder = false,
  });

  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isUpgrade;
  final bool useGradientBorder;

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).isLightMode;

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          FlowyTooltip(
            message: tooltip,
            child: GestureDetector(
              onTap: onPressed,
              child: MouseRegion(
                cursor: onPressed != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: _drawBorder(
                  context,
                  isLM: isLM,
                  isUpgrade: isUpgrade,
                  child: Container(
                    height: 36,
                    width: 148,
                    decoration: BoxDecoration(
                      color: useGradientBorder
                          ? Theme.of(context).cardColor
                          : Colors.transparent,
                      border: Border.all(color: Colors.transparent),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: _drawText(label, isLM, isUpgrade)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawText(String text, bool isLM, bool isUpgrade) {
    final child = FlowyText(
      text,
      fontSize: 14,
      lineHeight: 1.2,
      fontWeight: useGradientBorder ? FontWeight.w600 : FontWeight.w500,
      color: isUpgrade ? const Color(0xFFC49BEC) : null,
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

  Widget _drawBorder(
    BuildContext context, {
    required bool isLM,
    required bool isUpgrade,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: isUpgrade
            ? LinearGradient(
                transform: const GradientRotation(-1.2),
                stops: const [0.4, 1],
                colors: [
                  isLM ? const Color(0xFF251D37) : const Color(0xFF7459AD),
                  isLM ? const Color(0xFF7547C0) : const Color(0xFFDDC8FF),
                ],
              )
            : null,
        border: isUpgrade ? null : Border.all(color: const Color(0xFF333333)),
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
  });

  final String title;
  final String? description;
  final bool isPrimary;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 185,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(left: 12 + (!isPrimary ? 12 : 0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FlowyText.semibold(
                    title,
                    fontSize: 24,
                    overflow: TextOverflow.ellipsis,
                    color: isPrimary
                        ? AFThemeExtension.of(context).strongText
                        : Theme.of(context).isLightMode
                            ? const Color(0xFF5C3699)
                            : const Color(0xFFC49BEC),
                  ),
                ),
              ],
            ),
            if (description != null && description!.isNotEmpty) ...[
              const VSpace(4),
              FlowyText.regular(
                description!,
                fontSize: 12,
                maxLines: 3,
                lineHeight: 1.5,
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
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemFour.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemFive.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemSix.tr(),
    tooltip: LocaleKeys.settings_comparePlanDialog_planLabels_tooltipSix.tr(),
  ),
  _PlanItem(
    label: LocaleKeys.settings_comparePlanDialog_planLabels_itemSeven.tr(),
    tooltip: LocaleKeys.settings_comparePlanDialog_planLabels_tooltipSeven.tr(),
  ),
];

class _CellItem {
  const _CellItem(this.label, {this.icon});

  final String label;
  final FlowySvgData? icon;
}

final List<_CellItem> _freeLabels = [
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemOne.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemTwo.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemThree.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemFour.tr(),
    icon: FlowySvgs.check_m,
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemFive.tr(),
    icon: FlowySvgs.check_m,
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemSix.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_freeLabels_itemSeven.tr(),
  ),
];

final List<_CellItem> _proLabels = [
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemOne.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemTwo.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemThree.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemFour.tr(),
    icon: FlowySvgs.check_m,
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemFive.tr(),
    icon: FlowySvgs.check_m,
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemSix.tr(),
  ),
  _CellItem(
    LocaleKeys.settings_comparePlanDialog_proLabels_itemSeven.tr(),
    icon: FlowySvgs.check_m,
  ),
];
