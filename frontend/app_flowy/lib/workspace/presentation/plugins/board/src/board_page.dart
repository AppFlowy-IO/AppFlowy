// ignore_for_file: unused_field

import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class BoardPage extends StatelessWidget {
  final ViewPB _view;

  const BoardPage({required ViewPB view, Key? key})
      : _view = view,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
