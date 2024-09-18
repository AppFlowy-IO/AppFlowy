import 'dart:async';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
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
    return ViewPageBottomSheet(
      view: view,
      onAction: (action) async {
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
          case MobileViewBottomSheetBodyAction.publish:
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
              context.pop();
            }
            break;
          case MobileViewBottomSheetBodyAction.unpublish:
            context.read<ShareBloc>().add(const ShareEvent.unPublish());
            showToastNotification(
              context,
              message: LocaleKeys.publish_unpublishSuccessfully.tr(),
            );
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.copyPublishLink:
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
            context.pop();
            break;
          case MobileViewBottomSheetBodyAction.visitSite:
            final url = context.read<ShareBloc>().state.url;
            if (url.isNotEmpty) {
              unawaited(
                afLaunchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                ),
              );
            }
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
