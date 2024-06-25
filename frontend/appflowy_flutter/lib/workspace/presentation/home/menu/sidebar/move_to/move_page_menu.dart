import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovePageMenu extends StatefulWidget {
  const MovePageMenu({
    super.key,
    required this.userProfile,
    required this.workspaceId,
    required this.onSelected,
  });

  final UserProfilePB userProfile;
  final String workspaceId;
  final void Function(ViewPB view) onSelected;

  @override
  State<MovePageMenu> createState() => _MovePageMenuState();
}

class _MovePageMenuState extends State<MovePageMenu> {
  final isExpandedNotifier = PropertyValueNotifier(true);
  final isHoveredNotifier = ValueNotifier(false);

  @override
  void dispose() {
    isExpandedNotifier.dispose();
    isHoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SpaceBloc()
        ..add(
          SpaceEvent.initial(
            widget.userProfile,
            widget.workspaceId,
            openFirstPage: false,
          ),
        ),
      child: BlocBuilder<SpaceBloc, SpaceState>(
        builder: (context, state) {
          final space = state.currentSpace;
          if (space == null) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SpacePopup(
                child: CurrentSpace(
                  space: space,
                ),
              ),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => isHoveredNotifier.value = true,
                  onExit: (_) => isHoveredNotifier.value = false,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: SpacePages(
                      space: space,
                      isHovered: isHoveredNotifier,
                      isExpandedNotifier: isExpandedNotifier,
                      // hide the hover status and disable the editing actions
                      disableSelectedStatus: true,
                      // hide the ... and + buttons
                      rightIconsBuilder: (context, view) => [],
                      onSelected: (_, view) => widget.onSelected(view),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
