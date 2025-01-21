import 'package:flutter/material.dart';

class BarrierDialog {
  BarrierDialog(this.context);

  late BuildContext loadingContext;
  final BuildContext context;

  void show() => showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) {
          loadingContext = context;
          return const SizedBox.shrink();
        },
      );

  void dismiss() => Navigator.of(loadingContext).pop();
}
