import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/presentation/home/hotkeys.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/space/folder_space_pages.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/presentation/widgets/folder_space_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/create_space_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FolderSpaceSection extends StatelessWidget {
  const FolderSpaceSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpaceBloc, SpaceState>(
      builder: (context, state) {
        final spaces = state.spaces;
        final currentSpace = state.currentSpace ?? spaces.firstOrNull;
        if (spaces.isEmpty || currentSpace == null) {
          return const SizedBox.shrink();
        }
        return _Space(
          currentSpace: currentSpace,
          isExpanded: state.isExpanded,
        );
      },
    );
  }
}

class _Space extends StatefulWidget {
  const _Space({
    required this.currentSpace,
    required this.isExpanded,
  });

  final bool isExpanded;
  final FolderViewPB currentSpace;

  @override
  State<_Space> createState() => _SpaceState();
}

class _SpaceState extends State<_Space> {
  final isHovered = ValueNotifier(false);
  final isExpandedNotifier = PropertyValueNotifier(false);

  @override
  void initState() {
    super.initState();

    switchToTheNextSpace.addListener(_switchToNextSpace);
  }

  @override
  void dispose() {
    switchToTheNextSpace.removeListener(_switchToNextSpace);
    isHovered.dispose();
    isExpandedNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FolderSpaceMenu(
          isExpanded: widget.isExpanded,
          space: widget.currentSpace,
          onAdded: (layout) => _showCreatePagePopup(
            context,
            widget.currentSpace,
            layout,
          ),
          onCreateNewSpace: () => _showCreateSpaceDialog(context),
          onCollapseAllPages: () => isExpandedNotifier.value = true,
        ),
        if (widget.isExpanded)
          MouseRegion(
            onEnter: (_) => isHovered.value = true,
            onExit: (_) => isHovered.value = false,
            child: FolderSpacePages(
              isExpandedNotifier: isExpandedNotifier,
              space: widget.currentSpace,
              isHovered: isHovered,
              onSelected: (context, view) {
                if (HardwareKeyboard.instance.isControlPressed) {
                  context.read<TabsBloc>().openTab(view.viewPB);
                }
                context.read<TabsBloc>().openPlugin(view.viewPB);
              },
              onTertiarySelected: (context, view) =>
                  context.read<TabsBloc>().openTab(view.viewPB),
            ),
          ),
      ],
    );
  }

  void _showCreatePagePopup(
    BuildContext context,
    FolderViewPB space,
    ViewLayoutPB layout,
  ) {
    context.read<SpaceBloc>().add(
          SpaceEvent.createPage(
            name: '',
            layout: layout,
            index: 0,
            openAfterCreate: true,
          ),
        );

    context.read<SpaceBloc>().add(SpaceEvent.expand(space, true));
  }

  void _showCreateSpaceDialog(BuildContext context) {
    final spaceBloc = context.read<SpaceBloc>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: BlocProvider.value(
          value: spaceBloc,
          child: const CreateSpacePopup(),
        ),
      ),
    );
  }

  void _switchToNextSpace() {
    context.read<SpaceBloc>().add(const SpaceEvent.switchToNextSpace());
  }
}
