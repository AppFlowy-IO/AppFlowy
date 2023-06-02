import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import '../../workspace/presentation/home/home_stack.dart';

/// [DatabaseViewPlugin] is used to build the grid, calendar, and board.
/// It is a wrapper of the [Plugin] class. The underlying [Plugin] is
/// determined by the [ViewPB.pluginType] field.
///
class DatabaseViewPlugin extends Plugin {
  final ViewListener _viewListener;
  ViewPB _view;
  Plugin _innerPlugin;

  DatabaseViewPlugin({
    required ViewPB view,
  })  : _view = view,
        _innerPlugin = _makeInnerPlugin(view),
        _viewListener = ViewListener(view: view) {
    _listenOnLayoutChanged();
  }

  @override
  PluginId get id => _innerPlugin.id;

  @override
  PluginType get pluginType => _innerPlugin.pluginType;

  @override
  PluginWidgetBuilder get widgetBuilder => _innerPlugin.widgetBuilder;

  void _listenOnLayoutChanged() {
    _viewListener.start(
      onViewUpdated: (result) {
        result.fold(
          (updatedView) {
            if (_view.layout != updatedView.layout) {
              _innerPlugin = _makeInnerPlugin(updatedView);

              getIt<HomeStackManager>().setPlugin(_innerPlugin);
            }
            _view = updatedView;
          },
          (r) => null,
        );
      },
    );
  }
}

Plugin _makeInnerPlugin(ViewPB view) {
  return makePlugin(pluginType: view.pluginType, data: view);
}
