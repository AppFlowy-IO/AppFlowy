import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';

class SettingsPlanComparisonDialog extends StatefulWidget {
  const SettingsPlanComparisonDialog({super.key});

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
                          title: 'Free',
                          description:
                              'For organizing every corner of your work & life.',
                          price: '\$0',
                          priceInfo: 'free forever',
                          cells: _freeLabels,
                          isCurrent: true,
                          canUpgrade: false,
                          onSelected: () {},
                        ),
                        _PlanTable(
                          title: 'Professional',
                          description:
                              'A place for small groups to plan & get organized.',
                          price: '\$10 /month',
                          priceInfo: 'billed annually',
                          cells: _proLabels,
                          isCurrent: false,
                          canUpgrade: true,
                          onSelected: () {},
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
    required this.canUpgrade,
    required this.onSelected,
  });

  final String title;
  final String description;
  final String price;
  final String priceInfo;

  final List<String> cells;
  final bool isCurrent;
  final bool canUpgrade;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isCurrent && !canUpgrade
            ? null
            : const LinearGradient(
                colors: [
                  Color(0xFF251D37),
                  Color(0xFF7547C0),
                ],
              ),
      ),
      padding: isCurrent && !canUpgrade
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
              isPrimary: isCurrent && !canUpgrade,
              horizontalInset: 12,
            ),
            _Heading(
              title: price,
              description: priceInfo,
              isPrimary: isCurrent && !canUpgrade,
              height: 64,
              horizontalInset: 12,
            ),
            if (canUpgrade) ...[
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: _ActionButton(),
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
  const _ActionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 40,
                width: 152,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: FlowyText.medium(
                    'Upgrade',
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

const _planLabels = [
  _PlanItem(label: 'Workspaces'),
  _PlanItem(label: 'Members'),
  _PlanItem(
    label: 'Guests',
    tooltip:
        'Guests have read-only permissions to the specifically shared content',
  ),
  _PlanItem(
    label: 'Guest collaborators',
    tooltip: 'Guest collaborators are billed as one seat',
  ),
  _PlanItem(label: 'Storage'),
  _PlanItem(label: 'Real-time collaboration'),
  _PlanItem(label: 'Mobile app'),
  _PlanItem(label: 'AI Responses'),
];

const _freeLabels = [
  'charged per workspace',
  '3',
  '',
  '0',
  '5 GB',
  'yes',
  'yes',
  '1,000 (no refresh)',
];

const _proLabels = [
  'charged per workspace',
  'up to 10',
  '',
  '10 guests billed as one seat',
  'unlimited',
  'yes',
  'yes',
  '100,000 monthly',
];
