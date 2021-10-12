import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'item.dart';

class ViewListNotifier extends ChangeNotifier {
  List<View>? views;
  ViewListNotifier();

  set items(List<View> items) {
    views = items;
    notifyListeners();
  }

  List<View> get items => views ?? [];
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

  void update(ViewListNotifier notifier) {
    innerViews = notifier.items;
    notifyListeners();
  }
}

class ViewSection extends StatelessWidget {
  final List<View> views;
  const ViewSection(this.views, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The ViewListNotifier will be updated after ViewListData changed passed by parent widget
    return ChangeNotifierProxyProvider<ViewListNotifier, ViewSectionNotifier>(
      create: (_) {
        final views = Provider.of<ViewListNotifier>(
          context,
          listen: false,
        ).items;
        return ViewSectionNotifier(views);
      },
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (context, ViewSectionNotifier notifier, child) {
        return _renderSectionItems(context, notifier.views);
      }),
    );
  }

  Widget _renderSectionItems(BuildContext context, List<View> views) {
    var viewWidgets = views.map((view) {
      final item = ViewSectionItem(
        view: view,
        isSelected: _isViewSelected(context, view.id),
        onSelected: (view) => context.read<ViewSectionNotifier>().setSelectedView(view),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: item,
      );
    }).toList(growable: false);

    return Column(children: viewWidgets);
  }

  bool _isViewSelected(BuildContext context, String viewId) {
    final view = context.read<ViewSectionNotifier>().selectedView;
    if (view == null) {
      return false;
    }
    return view.id == viewId;
  }
}
