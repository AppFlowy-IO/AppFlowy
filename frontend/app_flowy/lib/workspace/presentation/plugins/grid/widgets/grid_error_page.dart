import 'package:flutter/material.dart';

class GridUnknownError extends StatelessWidget {
  const GridUnknownError({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
