import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/create_space_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSpace(4.0),
            for (final space in state.spaces)
              SizedBox(
                height: HomeSpaceViewSizes.viewHeight,
                child: _SidebarSpaceMenuItem(
                  space: space,
                  isSelected: state.currentSpace?.id == space.id,
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(
                height: 0.5,
              ),
            ),
            const SizedBox(
              height: HomeSpaceViewSizes.viewHeight,
              child: _CreateSpaceButton(),
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
    return FlowyButton(
      text: FlowyText.regular(space.name),
      iconPadding: 10,
      leftIcon: const FlowySvg(
        FlowySvgs.space_icon_s,
        blendMode: null,
      ),
      rightIcon: isSelected
          ? const FlowySvg(
              FlowySvgs.workspace_selected_s,
              blendMode: null,
            )
          : null,
      onTap: () {
        context.read<SpaceBloc>().add(SpaceEvent.open(space));
      },
    );
  }
}

class _CreateSpaceButton extends StatelessWidget {
  const _CreateSpaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      text: const FlowyText.regular('Create new space'),
      iconPadding: 10,
      leftIcon: const FlowySvg(
        FlowySvgs.space_add_s,
        blendMode: null,
      ),
      onTap: () {
        PopoverContainer.of(context).close();
        _showCreateSpaceDialog(context);
      },
    );
  }

  void _showCreateSpaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BlocProvider.value(
            value: context.read<SpaceBloc>(),
            child: const CreateSpacePopup(),
          ),
        );
      },
    );
  }
}
