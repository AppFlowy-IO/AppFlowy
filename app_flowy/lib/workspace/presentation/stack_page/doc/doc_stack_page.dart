import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/progress_indicator.dart';

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
      this,
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocBloc>(
            create: (context) => getIt<DocBloc>(param1: widget.view.id)..add(const DocEvent.loadDoc())),
      ],
      child: BlocBuilder<DocBloc, DocState>(builder: (context, state) {
        return state.map(
          loading: (_) => const FlowyProgressIndicator(),
          loadDoc: (s) => DocPage(doc: s.doc),
          loadFail: (s) {
            Log.error("$s");
            return FlowyErrorPage(s.error.toString());
          },
        );
      }),
    );
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
