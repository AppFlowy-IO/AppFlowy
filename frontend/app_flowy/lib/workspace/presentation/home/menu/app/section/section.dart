import 'dart:async';
import 'dart:developer';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:app_flowy/workspace/application/menu/menu_view_section_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/home/home_stack.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';
import 'package:styled_widget/styled_widget.dart';
import 'item.dart';

class ViewSection extends StatelessWidget {
  final AppViewDataContext appViewData;
  const ViewSection({Key? key, required this.appViewData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = ViewSectionBloc(appViewData: appViewData);
        bloc.add(const ViewSectionEvent.initial());
        return bloc;
      },
      child: BlocBuilder<ViewSectionBloc, ViewSectionState>(
        builder: (context, state) {
          return _SectionItems(views: state.views);
        },
      ),
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

class _SectionItems extends StatefulWidget {
  const _SectionItems({Key? key, required this.views}) : super(key: key);

  final List<View> views;

  @override
  State<_SectionItems> createState() => _SectionItemsState();
}

class _SectionItemsState extends State<_SectionItems> {
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
                    onSelected: (view) => getIt<MenuSharedState>().latestOpenView = view,
                  ).padding(vertical: 4),
                )
                .toList()[index],
          );
        },
      ),
    );
  }

  bool _isViewSelected(BuildContext context, String viewId) {
    // final view = context.read<ViewSectionNotifier>().selectedView;
    // if (view == null) {
    //   return false;
    // }
    // return view.id == viewId;
    return false;
  }
}

class ViewSectionNotifier with ChangeNotifier {
  bool isDisposed = false;
  List<View> _views;
  View? _selectedView;
  Timer? _notifyListenerOperation;
  VoidCallback? _latestViewDidChangeFn;

  ViewSectionNotifier({
    required List<View> views,
    View? initialSelectedView,
  })  : _views = views,
        _selectedView = initialSelectedView {
    _latestViewDidChangeFn = getIt<MenuSharedState>().addLatestViewListener((latestOpenView) {
      if (_views.contains(latestOpenView)) {
        selectedView = latestOpenView;
      } else {
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

  void update(AppViewDataContext notifier) {
    views = notifier.views;
  }

  void _notifyListeners() {
    _notifyListenerOperation?.cancel();
    _notifyListenerOperation = Timer(const Duration(milliseconds: 30), () {
      if (!isDisposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    isDisposed = true;
    _notifyListenerOperation?.cancel();
    if (_latestViewDidChangeFn != null) {
      getIt<MenuSharedState>().removeLatestViewListener(_latestViewDidChangeFn!);
      _latestViewDidChangeFn = null;
    }
    super.dispose();
  }
}
