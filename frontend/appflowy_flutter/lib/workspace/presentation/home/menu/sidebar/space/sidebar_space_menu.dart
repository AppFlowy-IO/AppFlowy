import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarSpaceMenu extends StatelessWidget {
  const SidebarSpaceMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        return Column(
          children: [
            const VSpace(4.0),
            for (final space in state.spaces)
              _SidebarSpaceMenuItem(
                space: space,
                isSelected: state.currentSpace?.id == space.id,
              ),
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
    return Row(
      children: [
        FlowyText(space.name),
        const Spacer(),
        if (isSelected) const Icon(Icons.check),
      ],
    );
  }
}
