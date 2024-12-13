import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/ai_chat/application/chat_select_message_bloc.dart';
import 'package:appflowy/plugins/ai_chat/chat_page.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/favorite_button.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/more_view_actions.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/common_view_action.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
  late final _chatMessageSelectorBloc =
      ChatSelectMessageBloc(viewNotifier: notifier);

  @override
  final ViewPluginNotifier notifier;

  @override
  PluginWidgetBuilder get widgetBuilder => AIChatPagePluginWidgetBuilder(
        viewInfoBloc: _viewInfoBloc,
        chatMessageSelectorBloc: _chatMessageSelectorBloc,
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
    _chatMessageSelectorBloc.close();
    notifier.dispose();
  }
}

class AIChatPagePluginWidgetBuilder extends PluginWidgetBuilder
    with NavigationItem {
  AIChatPagePluginWidgetBuilder({
    required this.viewInfoBloc,
    required this.chatMessageSelectorBloc,
    required this.notifier,
  });

  final ViewInfoBloc viewInfoBloc;
  final ChatSelectMessageBloc chatMessageSelectorBloc;
  final ViewPluginNotifier notifier;
  int? deletedViewIndex;

  @override
  String? get viewName => notifier.view.nameOrDefault;

  @override
  Widget get leftBarItem =>
      ViewTitleBar(key: ValueKey(notifier.view.id), view: notifier.view);

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      ViewTabBarItem(view: notifier.view, shortForm: shortForm);

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

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: chatMessageSelectorBloc),
        BlocProvider.value(value: viewInfoBloc),
      ],
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

  @override
  Widget? get rightBarItem => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: viewInfoBloc),
          BlocProvider.value(value: chatMessageSelectorBloc),
        ],
        child: BlocBuilder<ChatSelectMessageBloc, ChatSelectMessageState>(
          builder: (context, state) {
            if (state.isSelectingMessages) {
              return const SizedBox.shrink();
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ViewFavoriteButton(
                  key: ValueKey('favorite_button_${notifier.view.id}'),
                  view: notifier.view,
                ),
                const HSpace(4),
                MoreViewActions(
                  key: ValueKey(notifier.view.id),
                  view: notifier.view,
                  customActions: [
                    CustomViewAction(
                      view: notifier.view,
                      leftIcon: FlowySvgs.download_s,
                      label: LocaleKeys.moreAction_saveAsNewPage.tr(),
                      onTap: () {
                        chatMessageSelectorBloc.add(
                          const ChatSelectMessageEvent
                              .toggleSelectingMessages(),
                        );
                      },
                    ),
                    ViewAction(
                      type: ViewMoreActionType.divider,
                      view: notifier.view,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}
