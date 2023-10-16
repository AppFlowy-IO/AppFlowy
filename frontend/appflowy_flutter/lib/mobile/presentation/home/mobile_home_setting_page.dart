import 'package:flutter/material.dart';

class MobileHomeSettingPage extends StatelessWidget {
  const MobileHomeSettingPage({super.key});

  // sub-route path may not start or end with '/'
  static const routeName = 'MobileHomeSettingPage';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Setting Page')),
    );
  }
}
