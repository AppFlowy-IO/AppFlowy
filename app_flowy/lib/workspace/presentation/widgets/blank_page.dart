import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class BlankPageContext extends HomeStackContext {
  const BlankPageContext() : super(type: ViewType.Blank, title: 'Blank');

  @override
  List<Object> get props => [];
}

class BlankPage extends HomeStackWidget {
  const BlankPage({Key? key, required BlankPageContext context})
      : super(key: key, pageContext: context);

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
