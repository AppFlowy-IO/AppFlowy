import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
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
    final mentionBloc = context.read<MentionBloc>();
    return VisibilityDetector(
      key: ValueKey(id),
      child: child,
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction == 1.0;
        if (!context.mounted || mentionBloc.isClosed) return;
        if (isVisible) {
          mentionBloc.add(MentionEvent.addVisibleItem(id));
        } else {
          mentionBloc.add(MentionEvent.removeVisibleItem(id));
        }
      },
    );
  }
}
