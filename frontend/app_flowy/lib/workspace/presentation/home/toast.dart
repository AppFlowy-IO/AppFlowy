import 'package:app_flowy/startup/startup.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FlowyMessageToast extends StatelessWidget {
  final String message;
  const FlowyMessageToast({required this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: FlowyText.medium(message, color: Colors.white),
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: Colors.black,
      ),
    );
  }
}

void initToastWithContext(BuildContext context) {
  getIt<FToast>().init(context);
}

void showMessageToast(String message) {
  final child = FlowyMessageToast(message: message);

  getIt<FToast>().showToast(
    child: child,
    gravity: ToastGravity.BOTTOM,
    toastDuration: const Duration(seconds: 3),
  );
}
