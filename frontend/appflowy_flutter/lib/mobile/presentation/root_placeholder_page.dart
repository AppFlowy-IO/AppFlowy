import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// Widget for the root/initial pages in the bottom navigation bar.
class RootPlaceholderScreen extends StatelessWidget {
  /// Creates a RootScreen
  const RootPlaceholderScreen({
    required this.label,
    required this.detailsPath,
    this.secondDetailsPath,
    super.key,
  });

  /// The label
  final String label;

  /// The path to the detail page
  final String detailsPath;

  /// The path to another detail page
  final String? secondDetailsPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: FlowyText.medium(label),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
