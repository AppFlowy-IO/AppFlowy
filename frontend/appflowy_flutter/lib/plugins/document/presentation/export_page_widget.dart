import 'package:flowy_infra_ui/widget/rounded_button.dart';
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
        const FlowyText.medium(
          'Open document failed',
          fontSize: 18.0,
        ),
        const VSpace(5),
        const FlowyText.regular(
          'Please try to export the page and contact us.',
          fontSize: 12.0,
        ),
        const VSpace(20),
        RoundedTextButton(
          title: 'Export page',
          width: 100,
          height: 30,
          onPressed: onTap,
        )
      ],
    );
  }
}
