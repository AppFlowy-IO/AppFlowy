import 'dart:developer';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:styled_widget/styled_widget.dart';
import 'item.dart';
import 'package:async/async.dart';

class ViewSection extends StatelessWidget {
  final AppDataNotifier appData;
  const ViewSection({Key? key, required this.appData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The ViewSectionNotifier will be updated after AppDataNotifier changed passed by parent widget
    return ChangeNotifierProxyProvider<AppDataNotifier, ViewSectionNotifier>(
      create: (_) {
        return ViewSectionNotifier(
          context: context,
          views: appData.views,
          initialSelectedView: appData.selectedView,
        );
      },
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (context, ViewSectionNotifier notifier, child) {
        return RenderSectionItems(views: notifier.views);
      }),
    );
  }

  // Widget _renderSectionItems(BuildContext context, List<View> views) {
  //   List<Widget> viewWidgets = [];
  //   if (views.isNotEmpty) {
  //     viewWidgets = views
  //         .map(
  //           (view) => ViewSectionItem(
  //             view: view,
  //             isSelected: _isViewSelected(context, view.id),
  //             onSelected: (view) {
  //               context.read<ViewSectionNotifier>().selectedView = view;
  //               Provider.of<MenuSharedState>(context, listen: false).selectedView.value = view;
  //             },
  //           ).padding(vertical: 4),
  //         )
  //         .toList(growable: false);
  //   }

  //   return Column(children: viewWidgets);
  // }

  // bool _isViewSelected(BuildContext context, String viewId) {
  //   final view = context.read<ViewSectionNotifier>().selectedView;
  //   if (view == null) {
  //     return false;
  //   }
  //   return view.id == viewId;
  // }
}

class RenderSectionItems extends StatefulWidget {
  const RenderSectionItems({Key? key, required this.views}) : super(key: key);

  final List<View> views;

  @override
  State<RenderSectionItems> createState() => _RenderSectionItemsState();
}

class _RenderSectionItemsState extends State<RenderSectionItems> {
  List<View> views = <View>[];

  /// Maps the hasmap value of the section items to their index in the reorderable list.
  //TODO @gaganyadav80: Retain this map to persist the order of the items.
  final Map<String, int> _sectionItemIndex = <String, int>{};

  void _initItemList() {
    views.addAll(widget.views);

    for (int i = 0; i < views.length; i++) {
      if (_sectionItemIndex[views[i].id] == null) {
        _sectionItemIndex[views[i].id] = i;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initItemList();
  }

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) {
      _initItemList();
    }

    log("BUILD: Section items: ${views.length}");
    return ReorderableColumn(
      needsLongPressDraggable: false,
      onReorder: (oldIndex, index) {
        setState(() {
          // int index = newIndex > oldIndex ? newIndex - 1 : newIndex;
          View section = views.removeAt(oldIndex);
          views.insert(index, section);

          _sectionItemIndex[section.id] = index;
        });
      },
      children: List.generate(
        views.length,
        (index) {
          return Container(
            key: ValueKey(views[index].id),
            child: views
                .map(
                  (view) => ViewSectionItem(
                    view: view,
                    isSelected: _isViewSelected(context, view.id),
                    onSelected: (view) {
                      context.read<ViewSectionNotifier>().selectedView = view;
                      Provider.of<MenuSharedState>(context, listen: false).selectedView.value = view;
                    },
                  ).padding(vertical: 4),
                )
                .toList()[index],
          );
        },
      ),
    );
  }

  bool _isViewSelected(BuildContext context, String viewId) {
    final view = context.read<ViewSectionNotifier>().selectedView;
    if (view == null) {
      return false;
    }
    return view.id == viewId;
  }
}

class ViewSectionNotifier with ChangeNotifier {
  bool isDisposed = false;
  List<View> _views;
  View? _selectedView;
  CancelableOperation? _notifyListenerOperation;

  ViewSectionNotifier({
    required BuildContext context,
    required List<View> views,
    View? initialSelectedView,
  })  : _views = views,
        _selectedView = initialSelectedView {
    final menuSharedState = Provider.of<MenuSharedState>(context, listen: false);
    // The forcedOpenView will be the view after creating the new view
    menuSharedState.forcedOpenView.addPublishListener((forcedOpenView) {
      selectedView = forcedOpenView;
    });

    menuSharedState.selectedView.addListener(() {
      // Cancel the selected view of this section by setting the selectedView to null
      // that will notify the listener to refresh the ViewSection UI
      if (menuSharedState.selectedView.value != _selectedView) {
        selectedView = null;
      }
    });
  }

  set views(List<View> views) {
    if (_views != views) {
      _views = views;
      _notifyListeners();
    }
  }

  List<View> get views => _views;

  set selectedView(View? view) {
    if (_selectedView == view) {
      return;
    }
    _selectedView = view;
    _notifyListeners();

    if (view != null) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        getIt<HomeStackManager>().setPlugin(view.plugin());
      });
    } else {
      // do nothing
    }
  }

  View? get selectedView => _selectedView;

  void update(AppDataNotifier notifier) {
    views = notifier.views;
  }

  void _notifyListeners() {
    _notifyListenerOperation?.cancel();
    _notifyListenerOperation = CancelableOperation.fromFuture(
      Future.delayed(const Duration(milliseconds: 30), () {}),
    ).then((_) {
      if (!isDisposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    isDisposed = true;
    _notifyListenerOperation?.cancel();
    super.dispose();
  }
}
