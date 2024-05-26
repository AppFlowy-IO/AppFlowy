import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/chat_page.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  String get menuName => "AIChat";

  @override
  FlowySvgData get icon => FlowySvgs.ai_summary_s;

  @override
  PluginType get pluginType => PluginType.chat;

  @override
  ViewLayoutPB get layoutType => ViewLayoutPB.Chat;
}

class AIChatPluginConfig implements PluginConfig {
  @override
  bool get creatable => false;
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
  Widget get leftBarItem => FlowyText.medium(LocaleKeys.blankPageTitle.tr());

  @override
  Widget tabBarItem(String pluginId) => leftBarItem;

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
  }) {
    notifier.isDeleted.addListener(() {
      final deletedView = notifier.isDeleted.value;
      if (deletedView != null && deletedView.hasIndex()) {
        deletedViewIndex = deletedView.index;
      }
    });

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

  @override
  List<NavigationItem> get navigationItems => [this];
}
