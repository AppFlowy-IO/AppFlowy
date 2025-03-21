import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class JohnnyRobotApplication implements EntryPoint {
  @override
  Widget create(LaunchConfiguration config) {
    return SplashScreen(isAnon: config.isAnon);
  }
}

// Keep for backwards compatibility
class AppFlowyApplication extends JohnnyRobotApplication {}

// For backward compatibility
