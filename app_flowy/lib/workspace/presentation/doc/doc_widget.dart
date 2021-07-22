import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class DocPageContext extends HomeStackView {
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
  const DocPage({Key? key, required DocPageContext stackView})
      : super(key: key, stackView: stackView);

  @override
  _DocPageState createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  @override
  Widget build(BuildContext context) {
    assert(widget.stackView is DocPageContext);

    final context = widget.stackView as DocPageContext;
    final filename = _extractFilename(context.view.id);
    return Container();
  }

  String _extractFilename(String viewId) {
    return viewId.replaceFirst('doc_', '');
  }
}
