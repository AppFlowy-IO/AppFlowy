import 'dart:async';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/plugins/shared/share/publish_name_generator.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileViewPageMoreBottomSheet extends StatelessWidget {
  const MobileViewPageMoreBottomSheet({super.key, required this.view});

  final ViewPB view;
  @override
  Widget build(BuildContext context) {
    return BlocListener<ViewBloc, ViewState>(
      listener: (context, state) {
        if (state.successOrFailure.isSuccess && state.isDeleted) {
          context.go('/home');
        }
      },
      child: ViewPageBottomSheet(
        view: view,
        onAction: (action) async {
          switch (action) {
            case MobileViewBottomSheetBodyAction.duplicate:
              context.read<ViewBloc>().add(const ViewEvent.duplicate());
              context.pop();
              break;
            case MobileViewBottomSheetBodyAction.delete:
              context.read<ViewBloc>().add(const ViewEvent.delete());
              break;
            case MobileViewBottomSheetBodyAction.addToFavorites:
            case MobileViewBottomSheetBodyAction.removeFromFavorites:
              context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
              context.pop();
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
            case MobileViewBottomSheetBodyAction.publish:
              await _publish(context);
              if (context.mounted) {
                context.pop();
              }
              break;
            case MobileViewBottomSheetBodyAction.unpublish:
              _unpublish(context);
              context.pop();
              break;
            case MobileViewBottomSheetBodyAction.copyPublishLink:
              _copyPublishLink(context);
              context.pop();
              break;
            case MobileViewBottomSheetBodyAction.visitSite:
              _visitPublishedSite(context);
              context.pop();
              break;
            case MobileViewBottomSheetBodyAction.copyShareLink:
              _copyShareLink(context);
              context.pop();
              break;
            case MobileViewBottomSheetBodyAction.rename:
              // no need to implement, rename is handled by the onRename callback.
              throw UnimplementedError();
          }
        },
        onRename: (name) {
          _onRename(context, name);
          context.pop();
        },
      ),
    );
  }

  Future<void> _publish(BuildContext context) async {
    final id = context.read<ShareBloc>().view.id;
    final publishName = await generatePublishName(
      id,
      view.name,
    );
    if (context.mounted) {
      context.read<ShareBloc>().add(
            ShareEvent.publish(
              '',
              publishName,
              [view.id],
            ),
          );
      showToastNotification(
        context,
        message: LocaleKeys.publish_publishSuccessfully.tr(),
      );
    }
  }

  void _unpublish(BuildContext context) {
    context.read<ShareBloc>().add(const ShareEvent.unPublish());
    showToastNotification(
      context,
      message: LocaleKeys.publish_unpublishSuccessfully.tr(),
    );
  }

  void _copyPublishLink(BuildContext context) {
    final url = context.read<ShareBloc>().state.url;
    if (url.isNotEmpty) {
      unawaited(
        getIt<ClipboardService>().setData(
          ClipboardServiceData(plainText: url),
        ),
      );
      showToastNotification(
        context,
        message: LocaleKeys.grid_url_copy.tr(),
      );
    }
  }

  void _visitPublishedSite(BuildContext context) {
    final url = context.read<ShareBloc>().state.url;
    if (url.isNotEmpty) {
      unawaited(
        afLaunchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        ),
      );
    }
  }

  void _copyShareLink(BuildContext context) {
    final workspaceId = context.read<ShareBloc>().state.workspaceId;
    final viewId = context.read<ShareBloc>().state.viewId;
    final url = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: viewId,
    );
    if (url.isNotEmpty) {
      unawaited(
        getIt<ClipboardService>().setData(
          ClipboardServiceData(plainText: url),
        ),
      );
      showToastNotification(
        context,
        message: LocaleKeys.shareAction_copyLinkSuccess.tr(),
      );
    } else {
      showToastNotification(
        context,
        message: LocaleKeys.shareAction_copyLinkToBlockFailed.tr(),
        type: ToastificationType.error,
      );
    }
  }

  void _onRename(BuildContext context, String name) {
    if (name != view.name) {
      context.read<ViewBloc>().add(ViewEvent.rename(name));
    }
  }
}
