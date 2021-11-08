import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/i_view.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flutter/material.dart';

import 'doc_page.dart';

class DocStackContext extends HomeStackContext {
  View _view;
  late IViewListener _listener;
  final ValueNotifier<String> _isUpdated = ValueNotifier<String>("");

  DocStackContext({required View view, Key? key}) : _view = view {
    _listener = getIt<IViewListener>(param1: view);
    _listener.updatedNotifier.addPublishListener((result) {
      result.fold(
        (newView) {
          _view = newView;
          _isUpdated.value = _view.name;
        },
        (error) {},
      );
    });
    _listener.start();
  }

  @override
  Widget get naviTitle => FlowyText.medium(_view.name, fontSize: 12);
  @override
  String get identifier => _view.id;
  @override
  HomeStackType get type => _view.stackType();

  @override
  Widget buildWidget() {
    return DocStackPage(_view, key: ValueKey(_view.id));
  }

  @override
  List<NavigationItem> get navigationItems => _makeNavigationItems();

  @override
  ValueNotifier<String> get isUpdated => _isUpdated;

  // List<NavigationItem> get navigationItems => naviStacks.map((stack) {
  //       return NavigationItemImpl(context: stack);
  //     }).toList();

  List<NavigationItem> _makeNavigationItems() {
    return [
      this,
    ];
  }

  @override
  void dispose() {
    _listener.stop();
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
