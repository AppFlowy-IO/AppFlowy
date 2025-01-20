import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewAction extends StatelessWidget {
  const ViewAction({
    super.key,
    required this.type,
    required this.view,
    this.mutex,
  });

  final ViewMoreActionType type;
  final ViewPB view;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    final wrapper = ViewMoreActionTypeWrapper(
      type,
      view,
      (controller, data) async {
        await _onAction(context, data);
        mutex?.close();
      },
      moveActionDirection: PopoverDirection.leftWithTopAligned,
      moveActionOffset: const Offset(-10, 0),
    );
    return wrapper.buildWithContext(
      context,
      // this is a dummy controller, we don't need to control the popover here.
      PopoverController(),
      null,
    );
  }

  Future<void> _onAction(
    BuildContext context,
    dynamic data,
  ) async {
    switch (type) {
      case ViewMoreActionType.delete:
        final (containPublishedPage, _) =
            await ViewBackendService.containPublishedPage(view);

        if (containPublishedPage && context.mounted) {
          await showConfirmDeletionDialog(
            context: context,
            name: view.nameOrDefault,
            description: LocaleKeys.publish_containsPublishedPage.tr(),
            onConfirm: () {
              context.read<ViewBloc>().add(const ViewEvent.delete());
            },
          );
        } else if (context.mounted) {
          context.read<ViewBloc>().add(const ViewEvent.delete());
        }
      case ViewMoreActionType.duplicate:
        context.read<ViewBloc>().add(const ViewEvent.duplicate());
      case ViewMoreActionType.moveTo:
        final value = data;
        if (value is! (ViewPB, ViewPB)) {
          return;
        }
        final space = value.$1;
        final target = value.$2;
        final result = await ViewBackendService.getView(view.parentViewId);
        result.fold(
          (parentView) => moveViewCrossSpace(
            context,
            space,
            view,
            parentView,
            FolderSpaceType.public,
            view,
            target.id,
          ),
          (f) => Log.error(f),
        );

        // the move action is handled in the button itself
        break;
      default:
        throw UnimplementedError();
    }
  }
}

class CustomViewAction extends StatelessWidget {
  const CustomViewAction({
    super.key,
    required this.view,
    required this.leftIcon,
    required this.label,
    this.onTap,
    this.mutex,
  });

  final ViewPB view;
  final FlowySvgData leftIcon;
  final String label;
  final VoidCallback? onTap;
  final PopoverMutex? mutex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: FlowyIconTextButton(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        onTap: onTap,
        leftIconBuilder: (onHover) => FlowySvg(leftIcon),
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText(
          label,
          figmaLineHeight: 18.0,
        ),
      ),
    );
  }
}
