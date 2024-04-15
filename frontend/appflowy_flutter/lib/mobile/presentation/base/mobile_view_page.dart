import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/presentation/document_collaborators.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/page_style_bottom_sheet.dart';
import 'package:appflowy/plugins/shared/sync_indicator.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  late final Future<FlowyResult<ViewPB, FlowyError>> future;

  @override
  void initState() {
    super.initState();
    future = ViewBackendService.getView(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final child = FutureBuilder(
      future: future,
      builder: (context, state) {
        Widget body;
        ViewPB? viewPB;
        final actions = <Widget>[];
        if (state.connectionState != ConnectionState.done) {
          body = const Center(
            child: CircularProgressIndicator(),
          );
        } else if (!state.hasData) {
          body = FlowyMobileStateContainer.error(
            emoji: '😔',
            title: LocaleKeys.error_weAreSorry.tr(),
            description: LocaleKeys.error_loadingViewError.tr(),
            errorMsg: state.error.toString(),
          );
        } else {
          body = state.data!.fold((view) {
            viewPB = view;
            actions.addAll([
              if (FeatureFlag.syncDocument.isOn) ...[
                DocumentCollaborators(
                  width: 60,
                  height: 44,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  view: view,
                ),
                const HSpace(16.0),
                DocumentSyncIndicator(view: view),
                const HSpace(8.0),
              ],
              _buildAppBarLayoutButton(view),
              _buildAppBarMoreButton(view),
            ]);
            final plugin = view.plugin(arguments: widget.arguments ?? const {})
              ..init();
            return plugin.widgetBuilder.buildWidget(shrinkWrap: false);
          }, (error) {
            return FlowyMobileStateContainer.error(
              emoji: '😔',
              title: LocaleKeys.error_weAreSorry.tr(),
              description: LocaleKeys.error_loadingViewError.tr(),
              errorMsg: error.toString(),
            );
          });
        }

        if (viewPB != null) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    FavoriteBloc()..add(const FavoriteEvent.initial()),
              ),
              BlocProvider(
                create: (_) =>
                    ViewBloc(view: viewPB!)..add(const ViewEvent.initial()),
              ),
              BlocProvider.value(
                value: getIt<ReminderBloc>()
                  ..add(const ReminderEvent.started()),
              ),
              if (viewPB!.layout == ViewLayoutPB.Document)
                BlocProvider(
                  create: (_) => DocumentPageStyleBloc(view: viewPB!),
                ),
            ],
            child: Builder(
              builder: (context) {
                final view = context.watch<ViewBloc>().state.view;
                return _buildApp(view, actions, body);
              },
            ),
          );
        } else {
          return _buildApp(null, [], body);
        }
      },
    );

    return child;
  }

  Widget _buildApp(ViewPB? view, List<Widget> actions, Widget child) {
    final icon = view?.icon.value;
    return Scaffold(
      appBar: FlowyAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && icon.isNotEmpty)
              EmojiText(
                emoji: '$icon ',
                fontSize: 22.0,
              ),
            Expanded(
              child: FlowyText.medium(
                view?.name ?? widget.title ?? '',
                fontSize: 15.0,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }

  Widget _buildAppBarLayoutButton(ViewPB view) {
    // only display the layout button if the view is a document
    if (view.layout != ViewLayoutPB.Document) {
      return const SizedBox.shrink();
    }

    return AppBarButton(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: (context) {
        EditorNotification.exitEditing().post();

        showMobileBottomSheet(
          context,
          showDragHandle: true,
          showDivider: false,
          showDoneButton: true,
          showHeader: true,
          title: LocaleKeys.pageStyle_title.tr(),
          backgroundColor: Theme.of(context).colorScheme.background,
          builder: (_) => BlocProvider.value(
            value: context.read<DocumentPageStyleBloc>(),
            child: const PageStyleBottomSheet(),
          ),
        );
      },
      child: const FlowySvg(FlowySvgs.m_layout_s),
    );
  }

  Widget _buildAppBarMoreButton(ViewPB view) {
    return AppBarButton(
      padding: const EdgeInsets.only(left: 8, right: 16),
      onTap: (context) {
        EditorNotification.exitEditing().post();

        showMobileBottomSheet(
          context,
          showDragHandle: true,
          showDivider: false,
          backgroundColor: Theme.of(context).colorScheme.background,
          builder: (_) => _buildAppBarMoreBottomSheet(context),
        );
      },
      child: const FlowySvg(FlowySvgs.m_app_bar_more_s),
    );
  }

  Widget _buildAppBarMoreBottomSheet(BuildContext context) {
    final view = context.read<ViewBloc>().state.view;
    return ViewPageBottomSheet(
      view: view,
      onAction: (action) {
        switch (action) {
          case MobileViewBottomSheetBodyAction.duplicate:
            context.pop();
            context.read<ViewBloc>().add(const ViewEvent.duplicate());
            // show toast
            break;
          case MobileViewBottomSheetBodyAction.share:
            // unimplemented
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.delete:
            // pop to home page
            context
              ..pop()
              ..pop();
            context.read<ViewBloc>().add(const ViewEvent.delete());
            break;
          case MobileViewBottomSheetBodyAction.addToFavorites:
          case MobileViewBottomSheetBodyAction.removeFromFavorites:
            context.pop();
            context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
            break;
          case MobileViewBottomSheetBodyAction.undo:
            EditorNotification.undo().post();
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.redo:
            EditorNotification.redo().post();
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.helpCenter:
            // unimplemented
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.rename:
            // no need to implement, rename is handled by the onRename callback.
            throw UnimplementedError();
        }
      },
      onRename: (name) {
        if (name != view.name) {
          context.read<ViewBloc>().add(ViewEvent.rename(name));
        }
        context.pop();
      },
    );
  }
}
