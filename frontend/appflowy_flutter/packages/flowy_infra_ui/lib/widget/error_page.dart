import 'package:flutter/material.dart';

class FlowyErrorPage extends StatelessWidget {
  final String error;
  const FlowyErrorPage(this.error, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(error);
  }
}
