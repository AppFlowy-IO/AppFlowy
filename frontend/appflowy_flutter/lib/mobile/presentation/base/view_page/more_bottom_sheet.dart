import 'dart:async';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/workspaces/create_workspace_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_notification.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/plugins/shared/share/publish_name_generator.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/shared/error_code/error_code_map.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class MobileViewPageMoreBottomSheet extends StatelessWidget {
  const MobileViewPageMoreBottomSheet({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ShareBloc, ShareState>(
      listener: (context, state) => _showToast(context, state),
      child: BlocListener<ViewBloc, ViewState>(
        listener: (context, state) {
          if (state.successOrFailure.isSuccess && state.isDeleted) {
            context.go('/home');
          }
        },
        child: ViewPageBottomSheet(
          view: view,
          onAction: (action) async => _onAction(context, action),
          onRename: (name) {
            _onRename(context, name);
            context.pop();
          },
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    MobileViewBottomSheetBodyAction action,
  ) async {
    switch (action) {
      case MobileViewBottomSheetBodyAction.duplicate:
        _duplicate(context);
        break;
      case MobileViewBottomSheetBodyAction.delete:
        context.read<ViewBloc>().add(const ViewEvent.delete());
        context.pop();
        break;
      case MobileViewBottomSheetBodyAction.addToFavorites:
        _addFavorite(context);
        break;
      case MobileViewBottomSheetBodyAction.removeFromFavorites:
        _removeFavorite(context);
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
      case MobileViewBottomSheetBodyAction.updatePathName:
        _updatePathName(context);
      case MobileViewBottomSheetBodyAction.rename:
        // no need to implement, rename is handled by the onRename callback.
        throw UnimplementedError();
    }
  }

  Future<void> _publish(BuildContext context) async {
    final id = context.read<ShareBloc>().view.id;
    final lastPublishName = context.read<ShareBloc>().state.pathName;
    final publishName = lastPublishName.orDefault(
      await generatePublishName(
        id,
        view.name,
      ),
    );
    if (context.mounted) {
      context.read<ShareBloc>().add(
            ShareEvent.publish(
              '',
              publishName,
              [view.id],
            ),
          );
    }
  }

  void _duplicate(BuildContext context) {
    context.read<ViewBloc>().add(const ViewEvent.duplicate());
    context.pop();

    showToastNotification(
      context,
      message: LocaleKeys.button_duplicateSuccessfully.tr(),
    );
  }

  void _addFavorite(BuildContext context) {
    _toggleFavorite(context);

    showToastNotification(
      context,
      message: LocaleKeys.button_favoriteSuccessfully.tr(),
    );
  }

  void _removeFavorite(BuildContext context) {
    _toggleFavorite(context);

    showToastNotification(
      context,
      message: LocaleKeys.button_unfavoriteSuccessfully.tr(),
    );
  }

  void _toggleFavorite(BuildContext context) {
    context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view));
    context.pop();
  }

  void _unpublish(BuildContext context) {
    context.read<ShareBloc>().add(const ShareEvent.unPublish());
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

  void _updatePathName(BuildContext context) async {
    final shareBloc = context.read<ShareBloc>();
    final pathName = shareBloc.state.pathName;
    await showMobileBottomSheet(
      context,
      showHeader: true,
      title: LocaleKeys.shareAction_updatePathName.tr(),
      showCloseButton: true,
      showDragHandle: true,
      showDivider: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      builder: (bottomSheetContext) {
        FlowyResult<void, FlowyError>? previousUpdatePathNameResult;
        return EditWorkspaceNameBottomSheet(
          type: EditWorkspaceNameType.edit,
          workspaceName: pathName,
          hintText: '',
          validator: (value) => null,
          validatorBuilder: (context) {
            return BlocProvider.value(
              value: shareBloc,
              child: BlocBuilder<ShareBloc, ShareState>(
                builder: (context, state) {
                  final updatePathNameResult = state.updatePathNameResult;

                  if (updatePathNameResult == null &&
                      previousUpdatePathNameResult == null) {
                    return const SizedBox.shrink();
                  }

                  if (updatePathNameResult != null) {
                    previousUpdatePathNameResult = updatePathNameResult;
                  }

                  final widget = previousUpdatePathNameResult?.fold(
                        (value) => const SizedBox.shrink(),
                        (error) => FlowyText(
                          error.code.publishErrorMessage.orDefault(
                            LocaleKeys.settings_sites_error_updatePathNameFailed
                                .tr(),
                          ),
                          maxLines: 3,
                          fontSize: 12,
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ) ??
                      const SizedBox.shrink();

                  return widget;
                },
              ),
            );
          },
          onSubmitted: (name) {
            // rename the path name
            Log.info('rename the path name, from: $pathName, to: $name');

            shareBloc.add(ShareEvent.updatePathName(name));
          },
        );
      },
    );
    shareBloc.add(const ShareEvent.clearPathNameResult());
  }

  void _showToast(BuildContext context, ShareState state) {
    if (state.publishResult != null) {
      state.publishResult!.fold(
        (value) => showToastNotification(
          context,
          message: LocaleKeys.publish_publishSuccessfully.tr(),
        ),
        (error) => showToastNotification(
          context,
          message: '${LocaleKeys.publish_publishFailed.tr()}: ${error.code}',
          type: ToastificationType.error,
        ),
      );
    } else if (state.unpublishResult != null) {
      state.unpublishResult!.fold(
        (value) => showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishSuccessfully.tr(),
        ),
        (error) => showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishFailed.tr(),
          description: error.msg,
          type: ToastificationType.error,
        ),
      );
    } else if (state.updatePathNameResult != null) {
      state.updatePathNameResult!.onSuccess(
        (value) {
          showToastNotification(
            context,
            message:
                LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
          );

          context.pop();
        },
      );
    }
  }
}
