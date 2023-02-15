import 'package:flutter/material.dart';

class Loading {
  Loading(
    this.context,
  );

  late BuildContext loadingContext;
  final BuildContext context;

  Future<void> start() async {
    return await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        loadingContext = context;
        return const SimpleDialog(
          elevation: 0.0,
          backgroundColor:
              Colors.transparent, // can change this to your prefered color
          children: <Widget>[
            Center(
              child: CircularProgressIndicator(),
            )
          ],
        );
      },
    );
  }

  Future<void> stop() async {
    Navigator.of(loadingContext).pop();
  }
}
