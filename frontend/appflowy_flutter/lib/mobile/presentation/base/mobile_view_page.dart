import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/base/mobile_view_page_bloc.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/document_collaborators.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileViewPage extends StatefulWidget {
  const MobileViewPage({
    super.key,
    required this.id,
    required this.viewLayout,
    this.title,
    this.arguments,
  });

  /// view id
  final String id;
  final ViewLayoutPB viewLayout;
  final String? title;
  final Map<String, dynamic>? arguments;

  @override
  State<MobileViewPage> createState() => _MobileViewPageState();
}

class _MobileViewPageState extends State<MobileViewPage> {
  // used to determine if the user has scrolled down and show the app bar in immersive mode
  ScrollNotificationObserverState? _scrollNotificationObserver;

  // control the app bar opacity when in immersive mode
  final ValueNotifier<double> _appBarOpacity = ValueNotifier(1.0);

  @override
  void dispose() {
    _appBarOpacity.dispose();
    _scrollNotificationObserver = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MobileViewPageBloc(viewId: widget.id)
        ..add(const MobileViewPageEvent.initial()),
      child: BlocBuilder<MobileViewPageBloc, MobileViewPageState>(
        builder: (context, state) {
          final view = state.result?.fold((s) => s, (f) => null);
          final body = _buildBody(context, state);

          if (view == null) {
            return _buildApp(context, null, body);
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    FavoriteBloc()..add(const FavoriteEvent.initial()),
              ),
              BlocProvider(
                create: (_) =>
                    ViewBloc(view: view)..add(const ViewEvent.initial()),
              ),
              BlocProvider.value(
                value: getIt<ReminderBloc>()
                  ..add(const ReminderEvent.started()),
              ),
              if (view.layout.isDocumentView)
                BlocProvider(
                  create: (_) => DocumentPageStyleBloc(view: view)
                    ..add(const DocumentPageStyleEvent.initial()),
                ),
            ],
            child: Builder(
              builder: (context) {
                final view = context.watch<ViewBloc>().state.view;
                return _buildApp(context, view, body);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildApp(
    BuildContext context,
    ViewPB? view,
    Widget child,
  ) {
    final isDocument = view?.layout.isDocumentView ?? false;
    final title = _buildTitle(context, view);
    final actions = _buildAppBarActions(context, view);
    final appBar = isDocument
        ? MobileViewPageImmersiveAppBar(
            preferredSize: Size(
              double.infinity,
              AppBarTheme.of(context).toolbarHeight ?? kToolbarHeight,
            ),
            title: title,
            appBarOpacity: _appBarOpacity,
            actions: actions,
          )
        : FlowyAppBar(title: title, actions: actions);
    final body = isDocument
        ? Builder(
            builder: (context) {
              _rebuildScrollNotificationObserver(context);
              return child;
            },
          )
        : child;
    return Scaffold(
      extendBodyBehindAppBar: isDocument,
      appBar: appBar,
      body: body,
    );
  }

  Widget _buildBody(BuildContext context, MobileViewPageState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final result = state.result;
    if (result == null) {
      return FlowyMobileStateContainer.error(
        emoji: '😔',
        title: LocaleKeys.error_weAreSorry.tr(),
        description: LocaleKeys.error_loadingViewError.tr(),
        errorMsg: '',
      );
    }

    return result.fold(
      (view) {
        final plugin = view.plugin(arguments: widget.arguments ?? const {})
          ..init();
        return plugin.widgetBuilder.buildWidget(
          shrinkWrap: false,
          context: PluginContext(userProfile: state.userProfilePB),
        );
      },
      (error) {
        return FlowyMobileStateContainer.error(
          emoji: '😔',
          title: LocaleKeys.error_weAreSorry.tr(),
          description: LocaleKeys.error_loadingViewError.tr(),
          errorMsg: error.toString(),
        );
      },
    );
  }

  // Document:
  //  - [ collaborators, sync_indicator, layout_button, more_button]
  // Database:
  //  - [ sync_indicator, more_button]
  List<Widget> _buildAppBarActions(BuildContext context, ViewPB? view) {
    if (view == null) {
      return [];
    }

    final isImmersiveMode =
        context.read<MobileViewPageBloc>().state.isImmersiveMode;
    final actions = <Widget>[];

    if (FeatureFlag.syncDocument.isOn) {
      // only document supports displaying collaborators.
      if (view.layout.isDocumentView) {
        actions.addAll([
          DocumentCollaborators(
            width: 60,
            height: 44,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(vertical: 8),
            view: view,
          ),
          const HSpace(12.0),
        ]);
      }
    }

    if (view.layout.isDocumentView) {
      actions.addAll([
        MobileViewPageLayoutButton(
          view: view,
          isImmersiveMode: isImmersiveMode,
          appBarOpacity: _appBarOpacity,
        ),
      ]);
    }

    actions.addAll([
      MobileViewPageMoreButton(
        view: view,
        isImmersiveMode: isImmersiveMode,
        appBarOpacity: _appBarOpacity,
      ),
    ]);

    return actions;
  }

  Widget _buildTitle(BuildContext context, ViewPB? view) {
    final icon = view?.icon.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null && icon.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 34.0),
            child: EmojiText(
              emoji: '$icon ',
              fontSize: 22.0,
            ),
          ),
        Expanded(
          child: FlowyText.medium(
            view?.name ?? widget.title ?? '',
            fontSize: 15.0,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _rebuildScrollNotificationObserver(BuildContext context) {
    _scrollNotificationObserver?.removeListener(_onScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_onScrollNotification);
  }

  // immersive mode related
  // auto show or hide the app bar based on the scroll position
  void _onScrollNotification(ScrollNotification notification) {
    if (_scrollNotificationObserver == null) {
      return;
    }

    if (notification is ScrollUpdateNotification &&
        defaultScrollNotificationPredicate(notification)) {
      final ScrollMetrics metrics = notification.metrics;
      double height = MediaQuery.of(context).padding.top;
      if (defaultTargetPlatform == TargetPlatform.android) {
        height += AppBarTheme.of(context).toolbarHeight ?? kToolbarHeight;
      }
      final progress = (metrics.pixels / height).clamp(0.0, 1.0);
      // reduce the sensitivity of the app bar opacity change
      if ((progress - _appBarOpacity.value).abs() >= 0.1 ||
          progress == 0 ||
          progress == 1.0) {
        _appBarOpacity.value = progress;
      }
    }
  }
}
