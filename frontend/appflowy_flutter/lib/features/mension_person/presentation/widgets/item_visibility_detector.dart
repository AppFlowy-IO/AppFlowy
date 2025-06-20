import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/mention_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MentionMenuItenVisibilityDetector extends StatelessWidget {
  const MentionMenuItenVisibilityDetector({
    super.key,
    required this.id,
    required this.child,
  });

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final renderBox = context.findRenderObject();
    final menuServiceInfo = context.read<MentionMenuServiceInfo>();
    if (renderBox is RenderBox) {
      menuServiceInfo.addItemHeightGetter(
        id,
        () => renderBox.localToGlobal(Offset.zero).dy,
      );
    }
    final bloc = context.read<MentionBloc>();
    return MouseRegion(
      onEnter: (e) => bloc.add(MentionEvent.selectItem(id)),
      child: VisibilityDetector(
        key: ValueKey(id),
        child: child,
        onVisibilityChanged: (info) {
          if (info.visibleFraction == 0.0) {
            menuServiceInfo.removeItemHeightGetter(id);
          }
        },
      ),
    );
  }
}
