import 'package:flutter/material.dart';

class MobileSignInScreen extends StatefulWidget {
  const MobileSignInScreen({super.key});

  @override
  State<MobileSignInScreen> createState() => _MobileSignInScreenState();
}

class _MobileSignInScreenState extends State<MobileSignInScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement signIn screen for mobile
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Sign in page'),
      ),
      body: const Placeholder(),
    );
  }
}
