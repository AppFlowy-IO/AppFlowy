import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingsPlanComparisonDialog extends StatelessWidget {
  const SettingsPlanComparisonDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const VSpace(24 + 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 248,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 100,
                        child: FlowyText.semibold(
                          'Plan\nFeatures',
                          fontSize: 24,
                          maxLines: 2,
                          color: Color(0xFF5C3699),
                        ),
                      ),
                      SizedBox(height: 64),
                      SizedBox(height: 56),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Heading(
                        title: 'Free',
                        description:
                            'For organizing every corner of your work & life.',
                      ),
                      const _Heading(
                        title: '\$10 /month',
                        description: 'billed annually',
                        height: 64,
                      ),
                      _ActionButton(),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Heading(
                        title: 'Professional',
                        description:
                            'A place for small groups to plan & get organized.',
                        isPrimary: false,
                      ),
                      _Heading(
                        title: '\$16 /month',
                        description: 'billed annually',
                        isPrimary: false,
                        height: 64,
                      ),
                      _ActionButton(),
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
                child: Center(
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
  });

  final String title;
  final String? description;
  final bool isPrimary;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: height,
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
    );
  }
}
