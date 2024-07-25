import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

@visibleForTesting
const Key mobileCreateNewPageButtonKey = Key('mobileCreateNewPageButtonKey');

class MobileSpaceHeader extends StatelessWidget {
  const MobileSpaceHeader({
    super.key,
    required this.space,
    required this.onPressed,
    required this.onAdded,
    required this.isExpanded,
  });

  final ViewPB space;
  final VoidCallback onPressed;
  final VoidCallback onAdded;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const HSpace(HomeSpaceViewSizes.mHorizontalPadding),
            SpaceIcon(
              dimension: 24,
              space: space,
              cornerRadius: 6.0,
            ),
            const HSpace(8),
            FlowyText.medium(
              space.name,
              lineHeight: 1.15,
              fontSize: 16.0,
            ),
            const HSpace(4.0),
            const FlowySvg(
              FlowySvgs.workspace_drop_down_menu_show_s,
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onAdded,
              child: Container(
                // expand the touch area
                margin: const EdgeInsets.symmetric(
                  horizontal: HomeSpaceViewSizes.mHorizontalPadding,
                ),
                child: const FlowySvg(
                  FlowySvgs.m_space_add_s,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> _onAction(SpaceMoreActionType type, dynamic data) async {
  //   switch (type) {
  //     case SpaceMoreActionType.rename:
  //       await _showRenameDialog();
  //       break;
  //     case SpaceMoreActionType.changeIcon:
  //       final (String icon, String iconColor) = data;
  //       context.read<SpaceBloc>().add(SpaceEvent.changeIcon(icon, iconColor));
  //       break;
  //     case SpaceMoreActionType.manage:
  //       _showManageSpaceDialog(context);
  //       break;
  //     case SpaceMoreActionType.addNewSpace:
  //       break;
  //     case SpaceMoreActionType.collapseAllPages:
  //       break;
  //     case SpaceMoreActionType.delete:
  //       _showDeleteSpaceDialog(context);
  //       break;
  //     case SpaceMoreActionType.divider:
  //       break;
  //   }
  // }

  // Future<void> _showRenameDialog() async {
  //   await NavigatorTextFieldDialog(
  //     title: LocaleKeys.space_rename.tr(),
  //     value: space.name,
  //     autoSelectAllText: true,
  //     onConfirm: (name, _) {
  //       context.read<SpaceBloc>().add(SpaceEvent.rename(space, name));
  //     },
  //   ).show(context);
  // }

  // void _showManageSpaceDialog(BuildContext context) {
  //   final spaceBloc = context.read<SpaceBloc>();
  //   showDialog(
  //     context: context,
  //     builder: (_) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12.0),
  //         ),
  //         child: BlocProvider.value(
  //           value: spaceBloc,
  //           child: const ManageSpacePopup(),
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _showDeleteSpaceDialog(BuildContext context) {
  //   final spaceBloc = context.read<SpaceBloc>();
  //   showDialog(
  //     context: context,
  //     builder: (_) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12.0),
  //         ),
  //         child: BlocProvider.value(
  //           value: spaceBloc,
  //           child: const SizedBox(width: 440, child: DeleteSpacePopup()),
  //         ),
  //       );
  //     },
  //   );
  // }
}
