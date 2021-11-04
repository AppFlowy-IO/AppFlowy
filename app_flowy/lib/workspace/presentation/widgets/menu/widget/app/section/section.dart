import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/menu.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/menu_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'item.dart';
import 'package:async/async.dart';

class ViewSection extends StatelessWidget {
  const ViewSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The ViewSectionNotifier will be updated after AppDataNotifier changed passed by parent widget
    return ChangeNotifierProxyProvider<AppDataNotifier, ViewSectionNotifier>(
      create: (_) {
        final views = Provider.of<AppDataNotifier>(context, listen: false).views;
        return ViewSectionNotifier(views, context);
      },
      update: (_, notifier, controller) => controller!..update(notifier),
      child: Consumer(builder: (context, ViewSectionNotifier notifier, child) {
        return _renderSectionItems(context, notifier.views);
      }),
    );
  }

  Widget _renderSectionItems(BuildContext context, List<View> views) {
    var viewWidgets = views.map(
      (view) => ViewSectionItem(
        view: view,
        isSelected: _isViewSelected(context, view.id),
        onSelected: (view) {
          context.read<ViewSectionNotifier>().selectedView = view;
          Provider.of<MenuSharedState>(context, listen: false).selectedView = view;
        },
      ).padding(vertical: 4),
    );

    return Column(children: viewWidgets.toList(growable: false));
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
  ViewSectionNotifier(List<View> views, BuildContext context) : _views = views {
    final menuSharedState = Provider.of<MenuSharedState>(context, listen: false);
    menuSharedState.addForcedOpenViewListener((forcedOpenView) {
      selectedView = forcedOpenView;
    });

    menuSharedState.addSelectedViewListener((currentSelectedView) {
      if (currentSelectedView != selectedView) {
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
        getIt<HomeStackManager>().setStack(view.stackContext());
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
