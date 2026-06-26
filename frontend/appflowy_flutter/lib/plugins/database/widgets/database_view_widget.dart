import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatabaseViewWidget extends StatefulWidget {
  const DatabaseViewWidget({
    super.key,
    required this.view,
    this.shrinkWrap = true,
    required this.showActions,
    required this.node,
    this.actionBuilder,
  });

  final ViewPB view;
  final bool shrinkWrap;
  final BlockComponentActionBuilder? actionBuilder;
  final bool showActions;
  final Node node;

  @override
  State<DatabaseViewWidget> createState() => _DatabaseViewWidgetState();
}

class _DatabaseViewWidgetState extends State<DatabaseViewWidget> {
  /// Listens to the view updates.
  late final ViewListener _listener;

  /// Notifies the view layout type changes. When the layout type changes,
  /// the widget of the view will be updated.
  late final ValueNotifier<ViewLayoutPB> _layoutTypeChangeNotifier;

  /// The view will be updated by the [ViewListener].
  late ViewPB view;

  late Plugin viewPlugin;

  @override
  void initState() {
    super.initState();
    view = widget.view;
    viewPlugin = view.plugin()..init();
    _listenOnViewUpdated();
  }

  @override
  void dispose() {
    _layoutTypeChangeNotifier.dispose();
    _listener.stop();
    viewPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? horizontalPadding = 0.0;
    final databasePluginWidgetBuilderSize =
        Provider.of<DatabasePluginWidgetBuilderSize?>(context);
    horizontalPadding = 40.0;
    if (databasePluginWidgetBuilderSize != null) {
      horizontalPadding = databasePluginWidgetBuilderSize.horizontalPadding;
    }

    return ValueListenableBuilder<ViewLayoutPB>(
      valueListenable: _layoutTypeChangeNotifier,
      builder: (_, __, ___) => viewPlugin.widgetBuilder.buildWidget(
        shrinkWrap: widget.shrinkWrap,
        context: PluginContext(),
        data: {
          kDatabasePluginWidgetBuilderHorizontalPadding: horizontalPadding,
          kDatabasePluginWidgetBuilderActionBuilder: widget.actionBuilder,
          kDatabasePluginWidgetBuilderShowActions: widget.showActions,
          kDatabasePluginWidgetBuilderNode: widget.node,
        },
      ),
    );
  }

  void _listenOnViewUpdated() {
    _listener = ViewListener(viewId: widget.view.id)
      ..start(
        onViewUpdated: (updatedView) {
          if (mounted) {
            view = updatedView;
            _layoutTypeChangeNotifier.value = view.layout;
          }
        },
      );

    _layoutTypeChangeNotifier = ValueNotifier(widget.view.layout);
  }
}
