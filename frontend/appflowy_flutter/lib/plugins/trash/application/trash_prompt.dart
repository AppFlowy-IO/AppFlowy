import 'package:flutter/material.dart';

void showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Yes'),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
