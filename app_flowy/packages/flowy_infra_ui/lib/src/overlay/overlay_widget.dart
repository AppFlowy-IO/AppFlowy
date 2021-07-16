import 'package:flutter/material.dart';

class Overlay extends StatelessWidget {
  const Overlay({
    Key? key,
    this.safeAreaEnabled = true,
  }) : super(key: key);

  final bool safeAreaEnabled;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
