import 'package:app_flowy/home/domain/page_context.dart';
import 'package:flutter/material.dart';

class BlankPageContext extends PageContext {
  const BlankPageContext() : super(PageType.blank, pageTitle: 'Blank');

  @override
  List<Object> get props => [];
}

class BlankPage extends HomeStackPage {
  const BlankPage({Key? key, required PageContext context})
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
