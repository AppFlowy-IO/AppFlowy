import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class DocPageContext extends HomeStackContext {
  final View view;
  DocPageContext(this.view)
      : super(
          type: view.viewType,
          title: view.name,
        );

  @override
  List<Object> get props => [view.id, type];
}

class DocPage extends HomeStackWidget {
  const DocPage({Key? key, required DocPageContext context})
      : super(key: key, pageContext: context);

  @override
  _DocPageState createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  @override
  Widget build(BuildContext context) {
    assert(widget.pageContext is DocPageContext);

    final context = widget.pageContext as DocPageContext;
    final filename = _extractFilename(context.view.id);
    return Container();
  }

  String _extractFilename(String viewId) {
    return viewId.replaceFirst('doc_', '');
  }
}
