import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pbserver.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BuiltInPageWidget extends StatefulWidget {
  const BuiltInPageWidget({
    super.key,
    required this.node,
    required this.editorState,
    required this.builder,
  });

  final Node node;
  final EditorState editorState;
  final Widget Function(ViewPB viewPB) builder;

  @override
  State<BuiltInPageWidget> createState() => _BuiltInPageWidgetState();
}

class _BuiltInPageWidgetState extends State<BuiltInPageWidget> {
  late Future<FlowyResult<ViewPB, FlowyError>> future;

  final focusNode = FocusNode();

  String get parentViewId => widget.node.attributes[DatabaseBlockKeys.parentID];
  String get childViewId => widget.node.attributes[DatabaseBlockKeys.viewID];

  @override
  void initState() {
    super.initState();
    future = ViewBackendService().getChildView(
      parentViewId: parentViewId,
      childViewId: childViewId,
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FlowyResult<ViewPB, FlowyError>>(
      builder: (context, snapshot) {
        final page = snapshot.data?.toNullable();
        if (snapshot.hasData && page != null) {
          return _build(context, page);
        }

        if (snapshot.connectionState == ConnectionState.done) {
          // Delete the page if not found
          WidgetsBinding.instance.addPostFrameCallback((_) => _deletePage());

          return const Center(child: FlowyText('Cannot load the page'));
        }

        return const Center(child: CircularProgressIndicator());
      },
      future: future,
    );
  }

  Widget _build(BuildContext context, ViewPB viewPB) {
    return MouseRegion(
      onEnter: (_) => widget.editorState.service.scrollService?.disable(),
      onExit: (_) => widget.editorState.service.scrollService?.enable(),
      child: _buildPage(context, viewPB),
    );
  }

  Widget _buildPage(BuildContext context, ViewPB view) {
    final verticalPadding =
        context.read<DatabasePluginWidgetBuilderSize?>()?.verticalPadding ??
            0.0;
    return Focus(
      focusNode: focusNode,
      onFocusChange: (value) {
        if (value) {
          widget.editorState.service.selectionService.clearSelection();
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: widget.builder(view),
      ),
    );
  }

  Future<void> _deletePage() async {
    final transaction = widget.editorState.transaction;
    transaction.deleteNode(widget.node);
    await widget.editorState.apply(transaction);
  }
}
