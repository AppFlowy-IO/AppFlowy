import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'item.dart';

class ViewSectionData extends ChangeNotifier {
  List<View>? innerViews;
  ViewSectionData();

  set views(List<View> views) {
    innerViews = views;
    notifyListeners();
  }

  List<View> get views => innerViews ?? [];
}

class ViewSectionNotifier with ChangeNotifier {
  List<View> innerViews;
  View? _selectedView;
  ViewSectionNotifier(this.innerViews);

  set views(List<View> views) => innerViews = views;
  List<View> get views => innerViews;

  void setSelectedView(View view) {
    _selectedView = view;
    notifyListeners();
  }

  View? get selectedView => _selectedView;

  void update(ViewSectionData notifier) {
    innerViews = notifier.views;
    notifyListeners();
  }
}

class ViewSection extends StatelessWidget {
  final List<View> views;
  const ViewSection(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The ViewListNotifier will be updated after ViewListData changed passed by parent widget
    return ChangeNotifierProxyProvider<ViewSectionData, ViewSectionNotifier>(
      create: (_) => ViewSectionNotifier(
        Provider.of<ViewSectionData>(
          context,
          listen: false,
        ).views,
      ),
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (context, ViewSectionNotifier notifier, child) {
        return _renderItems(context, notifier.views);
      }),
    );
  }

  Widget _renderItems(BuildContext context, List<View> views) {
    var viewWidgets = views.map((view) {
      final viewCtx = ViewWidgetContext(view);

      final item = ViewSectionItem(
        viewCtx: viewCtx,
        isSelected: _isViewSelected(context, view.id),
        onOpen: (view) {
          Log.debug("Open: $view");
          context.read<ViewSectionNotifier>().setSelectedView(view);
          final stackView = stackCtxFromView(viewCtx.view);
          getIt<HomeStackManager>().setStack(stackView);
        },
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: item,
      );
    }).toList(growable: false);

    return Column(
      children: viewWidgets,
    );
  }

  bool _isViewSelected(BuildContext context, String viewId) {
    final view = context.read<ViewSectionNotifier>().selectedView;
    if (view != null) {
      return view.id == viewId;
    } else {
      return false;
    }
  }
}
