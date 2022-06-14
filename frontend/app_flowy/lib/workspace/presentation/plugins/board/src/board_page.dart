// ignore_for_file: unused_field

import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/material.dart';

class BoardPage extends StatelessWidget {
  final View _view;

  const BoardPage({required View view, Key? key})
      : _view = view,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
