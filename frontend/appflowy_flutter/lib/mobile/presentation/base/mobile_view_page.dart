import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_state_container.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/document/document_page.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileViewPage extends StatefulWidget {
  const MobileViewPage({
    super.key,
    required this.id,
    this.title,
    required this.viewLayout,
  });

  /// view id
  final String id;
  final String? title;
  final ViewLayoutPB viewLayout;

  @override
  State<MobileViewPage> createState() => _MobileViewPageState();
}

class _MobileViewPageState extends State<MobileViewPage> {
  late final Future<Either<ViewPB, FlowyError>> future;

  @override
  void initState() {
    super.initState();

    future = ViewBackendService.getView(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            actions.add(_buildAppBarMoreButton(view));
            return view.plugin().widgetBuilder.buildWidget(shrinkWrap: false);
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
            ],
            child: Builder(
              builder: (context) {
                final view = context.watch<ViewBloc>().state.view;
                return _buildApp(
                  view,
                  actions,
                  body,
                );
              },
            ),
          );
        } else {
          return _buildApp(
            null,
            [],
            body,
          );
        }
      },
    );
  }

  Widget _buildApp(ViewPB? view, List<Widget> actions, Widget child) {
    final icon = view?.icon.value;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              EmojiText(
                emoji: '$icon ',
                fontSize: 22.0,
              ),
            Expanded(
              child: FlowyText.regular(
                view?.name ?? widget.title ?? '',
                fontSize: 14.0,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: AppBarBackButton(
          onTap: () => context.pop(),
        ),
        actions: actions,
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }

  Widget _buildAppBarMoreButton(ViewPB view) {
    return AppBarMoreButton(
      onTap: (context) {
        showMobileBottomSheet(
          context,
          showDragHandle: true,
          builder: (_) => _buildViewPageBottomSheet(context),
        );
      },
    );
  }

  Widget _buildViewPageBottomSheet(BuildContext context) {
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
            context.dispatchNotification(
              const EditorNotification(type: EditorNotificationType.redo),
            );
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.redo:
            context.pop();
            context.dispatchNotification(EditorNotification.redo());
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
