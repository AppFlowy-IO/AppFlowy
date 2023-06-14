import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class DatabaseViewWidget extends StatefulWidget {
  const DatabaseViewWidget({
    super.key,
    required this.view,
  });

  final ViewPB view;

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

  @override
  void initState() {
    super.initState();

    view = widget.view;
    _listenOnViewUpdated();
  }

  @override
  void dispose() {
    _layoutTypeChangeNotifier.dispose();
    _listener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ViewLayoutPB>(
      valueListenable: _layoutTypeChangeNotifier,
      builder: (_, __, ___) {
        return view.plugin().widgetBuilder.buildWidget();
      },
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
