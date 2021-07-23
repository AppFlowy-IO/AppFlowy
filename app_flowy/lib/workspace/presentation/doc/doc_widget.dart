import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

class DocPageStackView extends HomeStackView {
  final View view;
  DocPageStackView(this.view)
      : super(
          type: view.viewType,
          title: view.name,
        );

  @override
  List<Object> get props => [view.id, type];
}

class DocPage extends HomeStackWidget {
  const DocPage({Key? key, required DocPageStackView stackView})
      : super(key: key, stackView: stackView);

  @override
  _DocPageState createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  @override
  Widget build(BuildContext context) {
    assert(widget.stackView is DocPageStackView);

    final context = widget.stackView as DocPageStackView;
    final filename = _extractFilename(context.view.id);
    return Container();
  }

  String _extractFilename(String viewId) {
    return viewId.replaceFirst('doc_', '');
  }
}
