import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/feature_flag_page.dart';
import 'package:flutter/material.dart';

class FeatureFlagScreen extends StatelessWidget {
  const FeatureFlagScreen({
    super.key,
  });

  static const routeName = '/feature_flag';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feature Flags'),
      ),
      body: const FeatureFlagsPage(),
    );
  }
}
