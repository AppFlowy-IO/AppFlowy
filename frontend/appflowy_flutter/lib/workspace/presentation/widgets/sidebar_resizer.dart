import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarResizer extends StatefulWidget {
  const SidebarResizer({super.key});

  @override
  State<SidebarResizer> createState() => _SidebarResizerState();
}

class _SidebarResizerState extends State<SidebarResizer> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);
  final ValueNotifier<bool> isDragging = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    isDragging.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (details) {
          isDragging.value = true;

          context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeStart());
        },
        onHorizontalDragUpdate: (details) {
          isDragging.value = true;

          context
              .read<HomeSettingBloc>()
              .add(HomeSettingEvent.editPanelResized(details.localPosition.dx));
        },
        onHorizontalDragEnd: (details) {
          isDragging.value = false;

          context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeEnd());
        },
        onHorizontalDragCancel: () {
          isDragging.value = false;

          context
              .read<HomeSettingBloc>()
              .add(const HomeSettingEvent.editPanelResizeEnd());
        },
        child: ValueListenableBuilder(
          valueListenable: isHovered,
          builder: (context, isHovered, _) {
            return ValueListenableBuilder(
              valueListenable: isDragging,
              builder: (context, isDragging, _) {
                return Container(
                  width: 2,
                  // increase the width of the resizer to make it easier to drag
                  margin: const EdgeInsets.only(right: 2.0),
                  height: MediaQuery.of(context).size.height,
                  color: isHovered || isDragging
                      ? const Color(0xFF00B5FF)
                      : Colors.transparent,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
