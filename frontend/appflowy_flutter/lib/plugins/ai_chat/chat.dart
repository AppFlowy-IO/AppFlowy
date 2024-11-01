import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/ai_chat/chat_page.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AIChatPluginBuilder extends PluginBuilder {
  @override
  Plugin build(dynamic data) {
    if (data is ViewPB) {
      return AIChatPagePlugin(view: data);
    }

    throw FlowyPluginException.invalidData;
  }

  @override
  String get menuName => "AI Chat";

  @override
  FlowySvgData get icon => FlowySvgs.chat_ai_page_s;

  @override
  PluginType get pluginType => PluginType.chat;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Chat;
}

class AIChatPluginConfig implements PluginConfig {
  @override
  bool get creatable => true;
}

class AIChatPagePlugin extends Plugin {
  AIChatPagePlugin({
    required ViewPB view,
  }) : notifier = ViewPluginNotifier(view: view);

  late final ViewInfoBloc _viewInfoBloc;

  @override
  final ViewPluginNotifier notifier;

  @override
  PluginWidgetBuilder get widgetBuilder => AIChatPagePluginWidgetBuilder(
        bloc: _viewInfoBloc,
        notifier: notifier,
      );

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get pluginType => PluginType.chat;

  @override
  void init() {
    _viewInfoBloc = ViewInfoBloc(view: notifier.view)
      ..add(const ViewInfoEvent.started());
  }

  @override
  void dispose() {
    _viewInfoBloc.close();
    notifier.dispose();
  }
}

class AIChatPagePluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  AIChatPagePluginWidgetBuilder({
    required this.bloc,
    required this.notifier,
  });

  final ViewInfoBloc bloc;
  final ViewPluginNotifier notifier;
  int? deletedViewIndex;

  @override
  Widget get leftBarItem =>
      ViewTitleBar(key: ValueKey(notifier.view.id), view: notifier.view);

  @override
  Widget tabBarItem(String pluginId) => ViewTabBarItem(view: notifier.view);

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    notifier.isDeleted.addListener(_onDeleted);

    if (context.userProfile == null) {
      Log.error("User profile is null when opening AI Chat plugin");
      return const SizedBox();
    }

    return BlocProvider<ViewInfoBloc>.value(
      value: bloc,
      child: AIChatPage(
        userProfile: context.userProfile!,
        key: ValueKey(notifier.view.id),
        view: notifier.view,
        onDeleted: () =>
            context.onDeleted?.call(notifier.view, deletedViewIndex),
      ),
    );
  }

  void _onDeleted() {
    final deletedView = notifier.isDeleted.value;
    if (deletedView != null && deletedView.hasIndex()) {
      deletedViewIndex = deletedView.index;
    }
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  EdgeInsets get contentPadding => EdgeInsets.zero;
}
