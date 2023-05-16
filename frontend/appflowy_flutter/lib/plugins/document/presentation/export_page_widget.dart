import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class ExportPageWidget extends StatelessWidget {
  const ExportPageWidget({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FlowyText.regular(
          'There are some errors.',
          fontSize: 16.0,
        ),
        const SizedBox(
          height: 10,
        ),
        const FlowyText.regular(
          'Please try to export the page and contact us.',
          fontSize: 14.0,
        ),
        const SizedBox(
          height: 5,
        ),
        FlowyTextButton(
          'Export page',
          constraints: const BoxConstraints(maxWidth: 100),
          mainAxisAlignment: MainAxisAlignment.center,
          onPressed: onTap,
        )
      ],
    );
  }
}
