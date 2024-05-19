import 'package:appflowy/workspace/presentation/settings/pages/settings_plan_comparison_dialog.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingsPlanView extends StatelessWidget {
  const SettingsPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      autoSeparate: false,
      title: LocaleKeys.settings_planPage_title.tr(),
      children: const [
        _PlanUsageSummary(),
        _AddAICreditBox(),
        _CurrentPlanBox(),
        _DealBox(),
      ],
    );
  }
}

class _DealBox extends StatelessWidget {
  const _DealBox();

  @override
  Widget build(BuildContext context) {
    final isLM = Theme.of(context).brightness == Brightness.light;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: isLM ? null : [.2, .3, .6],
          transform: isLM ? null : const GradientRotation(-.9),
          begin: isLM ? Alignment.centerLeft : Alignment.topRight,
          end: isLM ? Alignment.centerRight : Alignment.bottomLeft,
          colors: [
            isLM
                ? const Color(0xFF7547C0).withAlpha(60)
                : const Color(0xFF7547C0),
            if (!isLM) const Color.fromARGB(255, 94, 57, 153),
            isLM
                ? const Color(0xFF251D37).withAlpha(60)
                : const Color(0xFF251D37),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const VSpace(18),
                      FlowyText.semibold(
                        LocaleKeys.settings_planPage_planUsage_deal_title.tr(),
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const VSpace(8),
                      FlowyText.medium(
                        LocaleKeys.settings_planPage_planUsage_deal_info.tr(),
                        maxLines: 6,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const VSpace(8),
                      FlowyGradientButton(
                        label: LocaleKeys
                            .settings_planPage_planUsage_deal_viewPlans
                            .tr(),
                        fontWeight: FontWeight.w500,
                        backgroundColor: isLM ? null : Colors.white,
                        textColor: isLM
                            ? Colors.white
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 9,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  transform: const GradientRotation(.7),
                  colors: [
                    if (isLM) const Color(0xFF7156DF),
                    isLM
                        ? const Color(0xFF3B2E8A)
                        : const Color(0xFFCE006F).withAlpha(150),
                    isLM ? const Color(0xFF261A48) : const Color(0xFF431459),
                  ],
                ),
              ),
              child: Center(
                child: FlowyText.semibold(
                  LocaleKeys.settings_planPage_planUsage_deal_bannerLabel.tr(),
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanBox extends StatelessWidget {
  const _CurrentPlanBox();

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
                      LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeTitle
                          .tr(),
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
                      onPressed: () => _openPricingDialog(context),
                    ),
                  ],
                ),
              ),
              const HSpace(16),
              Expanded(
                child: SeparatedColumn(
                  separatorBuilder: () => const VSpace(4),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeProOne
                          .tr(),
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeProTwo
                          .tr(),
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeProThree
                          .tr(),
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeProFour
                          .tr(),
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeConOne
                          .tr(),
                      isPro: false,
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeConTwo
                          .tr(),
                      isPro: false,
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeConThree
                          .tr(),
                      isPro: false,
                    ),
                    _ProConItem(
                      label: LocaleKeys
                          .settings_planPage_planUsage_currentPlan_freeConFour
                          .tr(),
                      isPro: false,
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

  void _openPricingDialog(BuildContext context) => showDialog(
        context: context,
        builder: (_) => const SettingsPlanComparisonDialog(),
      );
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

class FlowyGradientButton extends StatefulWidget {
  const FlowyGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.white,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final FontWeight fontWeight;

  /// Used to provide a custom foreground color for the button, used in cases
  /// where a custom [backgroundColor] is provided and the default text color
  /// does not have enough contrast.
  ///
  final Color textColor;

  /// Used to provide a custom background color for the button, this will
  /// override the gradient behavior, and is mostly used in rare cases
  /// where the gradient doesn't have contrast with the background.
  ///
  final Color? backgroundColor;

  @override
  State<FlowyGradientButton> createState() => _FlowyGradientButtonState();
}

class _FlowyGradientButtonState extends State<FlowyGradientButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onPressed?.call(),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovering = true),
        onExit: (_) => setState(() => isHovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(16),
            color: widget.backgroundColor,
            gradient: widget.backgroundColor != null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isHovering
                          ? const Color.fromARGB(255, 57, 40, 92)
                          : const Color(0xFF44326B),
                      isHovering
                          ? const Color.fromARGB(255, 96, 53, 164)
                          : const Color(0xFF7547C0),
                    ],
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: FlowyText(
              widget.label,
              fontSize: 16,
              fontWeight: widget.fontWeight,
              color: widget.textColor,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddAICreditBox extends StatelessWidget {
  const _AddAICreditBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText.semibold(
              LocaleKeys.settings_planPage_planUsage_aiCredit_title.tr(),
              fontSize: 18,
              color: AFThemeExtension.of(context).secondaryTextColor,
            ),
            const VSpace(8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 5,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FlowyText.semibold(
                          LocaleKeys.settings_planPage_planUsage_aiCredit_price
                              .tr(),
                          fontSize: 24,
                        ),
                        FlowyText.medium(
                          LocaleKeys
                              .settings_planPage_planUsage_aiCredit_priceDescription
                              .tr(),
                          fontSize: 14,
                          color:
                              AFThemeExtension.of(context).secondaryTextColor,
                        ),
                        const VSpace(8),
                        FlowyGradientButton(
                          label: LocaleKeys
                              .settings_planPage_planUsage_aiCredit_purchase
                              .tr(),
                        ),
                      ],
                    ),
                  ),
                ),
                const HSpace(16),
                Flexible(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowyText.regular(
                        LocaleKeys.settings_planPage_planUsage_aiCredit_info
                            .tr(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                      ),
                      const VSpace(8),
                      SeparatedColumn(
                        separatorBuilder: () => const VSpace(4),
                        children: [
                          _AIStarItem(
                            label: LocaleKeys
                                .settings_planPage_planUsage_aiCredit_infoItemOne
                                .tr(),
                          ),
                          _AIStarItem(
                            label: LocaleKeys
                                .settings_planPage_planUsage_aiCredit_infoItemTwo
                                .tr(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AIStarItem extends StatelessWidget {
  const _AIStarItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FlowySvg(FlowySvgs.ai_star_s, color: Color(0xFF750D7E)),
        const HSpace(4),
        Expanded(child: FlowyText(label, maxLines: 2)),
      ],
    );
  }
}

class _PlanUsageSummary extends StatelessWidget {
  const _PlanUsageSummary();

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
                  args: ['5', '20'],
                ),
                value: 0.25,
              ),
            ),
            Expanded(
              child: _UsageBox(
                title:
                    LocaleKeys.settings_planPage_planUsage_aiResponseLabel.tr(),
                label:
                    LocaleKeys.settings_planPage_planUsage_aiResponseUsage.tr(
                  args: ['750', '1,000'],
                ),
                value: .75,
              ),
            ),
          ],
        ),
        const VSpace(16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ToggleMore(
              value: false,
              label:
                  LocaleKeys.settings_planPage_planUsage_memberProToggle.tr(),
              badgeLabel: LocaleKeys.settings_planPage_planUsage_proBadge.tr(),
              onChanged: (value) {},
            ),
            const VSpace(8),
            _ToggleMore(
              value: false,
              label:
                  LocaleKeys.settings_planPage_planUsage_guestCollabToggle.tr(),
              badgeLabel: LocaleKeys.settings_planPage_planUsage_proBadge.tr(),
              onChanged: (value) {},
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

class _ToggleMore extends StatelessWidget {
  const _ToggleMore({
    required this.value,
    required this.label,
    this.badgeLabel,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final String? badgeLabel;
  final void Function(bool) onChanged;

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
          value: value,
          padding: EdgeInsets.zero,
          style: ToggleStyle.big,
          onChanged: onChanged,
        ),
        const HSpace(10),
        FlowyText.regular(label, fontSize: 14),
        if (badgeLabel != null && badgeLabel!.isNotEmpty) ...[
          const HSpace(10),
          SizedBox(
            height: 26,
            child: Badge(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              label: FlowyText.semibold(
                badgeLabel!,
                fontSize: 12,
                color: primaryColor,
              ),
              backgroundColor: secondaryColor,
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
              border: Border.all(
                color: const Color(0xFFDDF1F7).withOpacity(
                  theme.brightness == Brightness.light ? 1 : 0.1,
                ),
              ),
              color: AFThemeExtension.of(context).progressBarBGColor,
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
