import 'package:flutter/material.dart';

void showSnapBar(BuildContext context, String title, [Color? backgroundColor]) {
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          content: WillPopScope(
            onWillPop: () async {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              return true;
            },
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
          backgroundColor: backgroundColor,
        ),
      )
      .closed
      .then((value) => null);
}
