import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DatabaseViewWidget extends StatefulWidget {
  const DatabaseViewWidget({required this.view, super.key});

  final ViewPB view;

  @override
  State<DatabaseViewWidget> createState() => _DatabaseViewWidgetState();
}

class _DatabaseViewWidgetState extends State<DatabaseViewWidget> {
  /// Listens to the view updates.
  late ViewListener _listener;

  /// Notifies the view layout type changes. When the layout type changes,
  /// the widget of the view will be updated.
  late ViewLayoutTypeChangeNotifier _layoutTypeChangeNotifier;

  /// The view will be updated by the [ViewListener].
  late ViewPB view;

  @override
  void initState() {
    view = widget.view;
    _listener = ViewListener(view: widget.view);
    _listener.start(
      onViewUpdated: (result) {
        result.fold(
          (updatedView) {
            if (mounted) {
              view = updatedView;
              _layoutTypeChangeNotifier.setLayoutType(view.layout);
            }
          },
          (r) => null,
        );
      },
    );

    _layoutTypeChangeNotifier = ViewLayoutTypeChangeNotifier(
      layoutType: widget.view.layout,
    );

    super.initState();
  }

  @override
  void dispose() {
    _layoutTypeChangeNotifier.dispose();
    _listener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ViewLayoutTypeChangeNotifier>.value(
      value: _layoutTypeChangeNotifier,
      child: Consumer<ViewLayoutTypeChangeNotifier>(
        builder: (context, notifier, _) {
          return makePlugin(pluginType: view.pluginType, data: view)
              .widgetBuilder
              .buildWidget();
        },
      ),
    );
  }
}

class ViewLayoutTypeChangeNotifier extends ChangeNotifier {
  ViewLayoutPB _layoutType;

  ViewLayoutTypeChangeNotifier({
    required ViewLayoutPB layoutType,
  }) : _layoutType = layoutType;

  ViewLayoutPB get layoutType => _layoutType;

  void setLayoutType(ViewLayoutPB layoutType) {
    _layoutType = layoutType;
    notifyListeners();
  }
}
