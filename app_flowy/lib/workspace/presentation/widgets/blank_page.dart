import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class BlankStackView extends HomeStackView {
  const BlankStackView() : super(type: ViewType.Blank, title: 'Blank');

  @override
  List<Object> get props => [];
}

class BlankPage extends HomeStackWidget {
  const BlankPage({Key? key, required BlankStackView stackView})
      : super(key: key, stackView: stackView);

  @override
  State<StatefulWidget> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: const Center(
        child: Text(
          'Hello AppFlowy',
          style: TextStyle(fontSize: 60),
        ),
      ),
    );
  }
}
