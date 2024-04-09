import 'package:flutter/material.dart';

class Loading {
  Loading(this.context);

  BuildContext? loadingContext;
  final BuildContext context;

  Future<void> start() async => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          loadingContext = context;
          return const SimpleDialog(
            elevation: 0.0,
            backgroundColor:
                Colors.transparent, // can change this to your preferred color
            children: [
              Center(
                child: CircularProgressIndicator(),
              ),
            ],
          );
        },
      );

  Future<void> stop() async {
    if (loadingContext != null) {
      Navigator.of(loadingContext!).pop();
      loadingContext = null;
    }
  }
}

class BarrierDialog {
  BarrierDialog(this.context);

  late BuildContext loadingContext;
  final BuildContext context;

  Future<void> show() async => showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (BuildContext context) {
          loadingContext = context;
          return const SizedBox.shrink();
        },
      );

  Future<void> dismiss() async => Navigator.of(loadingContext).pop();
}
