import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSpaceMenu extends StatelessWidget {
  const MobileSpaceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(4.0),
            for (final space in state.spaces)
              SizedBox(
                height: 52,
                child: _SidebarSpaceMenuItem(
                  space: space,
                  isSelected: state.currentSpace?.id == space.id,
                ),
              ),
            // const Padding(
            //   padding: EdgeInsets.symmetric(vertical: 8.0),
            //   child: Divider(
            //     height: 0.5,
            //   ),
            // ),
            // const SizedBox(
            //   height: 52,
            //   child: _CreateSpaceButton(),
            // ),
          ],
        );
      },
    );
  }
}

class _SidebarSpaceMenuItem extends StatelessWidget {
  const _SidebarSpaceMenuItem({
    required this.space,
    required this.isSelected,
  });

  final ViewPB space;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: Row(
        children: [
          FlowyText.medium(
            space.name,
            fontSize: 16.0,
          ),
          const HSpace(6.0),
          if (space.spacePermission == SpacePermission.private)
            const FlowySvg(
              FlowySvgs.space_lock_s,
              size: Size.square(12),
            ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      iconPadding: 10,
      leftIcon: SpaceIcon(
        dimension: 24,
        space: space,
        svgSize: 18,
        cornerRadius: 6.0,
      ),
      leftIconSize: const Size.square(24),
      rightIcon: isSelected
          ? const FlowySvg(
              FlowySvgs.m_blue_check_s,
              blendMode: null,
            )
          : null,
      onTap: () {
        context.read<SpaceBloc>().add(SpaceEvent.open(space));
        Navigator.of(context).pop();
      },
    );
  }
}

// class _CreateSpaceButton extends StatelessWidget {
//   const _CreateSpaceButton();

//   @override
//   Widget build(BuildContext context) {
//     return FlowyButton(
//       text: FlowyText.regular(LocaleKeys.space_createNewSpace.tr()),
//       iconPadding: 10,
//       leftIcon: const FlowySvg(
//         FlowySvgs.space_add_s,
//       ),
//       leftIconSize: const Size.square(20),
//       onTap: () {
//         PopoverContainer.of(context).close();
//         _showCreateSpaceDialog(context);
//       },
//     );
//   }

//   void _showCreateSpaceDialog(BuildContext context) {
//     final spaceBloc = context.read<SpaceBloc>();
//     showDialog(
//       context: context,
//       builder: (_) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12.0),
//           ),
//           child: BlocProvider.value(
//             value: spaceBloc,
//             child: const CreateSpacePopup(),
//           ),
//         );
//       },
//     );
//   }
// }
