import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

import 'doc_page.dart';

class DocStackContext extends HomeStackContext {
  final View _view;
  DocStackContext({required View view, Key? key}) : _view = view;

  @override
  Widget get titleWidget => FlowyText.medium(_view.name, fontSize: 12);
  @override
  String get identifier => _view.id;
  @override
  HomeStackType get type => _view.stackType();

  @override
  List<Object?> get props => [_view.id];

  @override
  Widget render() {
    return DocStackPage(_view, key: ValueKey(_view.id));
  }

  @override
  List<NavigationItem> get navigationItems => makeNavigationItems();

  // List<NavigationItem> get navigationItems => naviStacks.map((stack) {
  //       return NavigationItemImpl(context: stack);
  //     }).toList();

  List<NavigationItem> makeNavigationItems() {
    return [
      this,
    ];
  }
}

class DocStackPage extends StatefulWidget {
  final View view;
  const DocStackPage(this.view, {Key? key}) : super(key: key);

  @override
  _DocStackPageState createState() => _DocStackPageState();
}

class _DocStackPageState extends State<DocStackPage> {
  @override
  Widget build(BuildContext context) {
    return DocPage(view: widget.view);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant DocStackPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}
