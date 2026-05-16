import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ViewTabBarItem extends StatefulWidget {
  const ViewTabBarItem({
    super.key,
    required this.view,
    this.shortForm = false,
  });

  final ViewPB view;
  final bool shortForm;

  @override
  State<ViewTabBarItem> createState() => _ViewTabBarItemState();
}

class _ViewTabBarItemState extends State<ViewTabBarItem> {
  late final ViewListener _viewListener;
  late ViewPB view;

  @override
  void initState() {
    super.initState();
    view = widget.view;
    _viewListener = ViewListener(viewId: widget.view.id);
    _viewListener.start(
      onViewUpdated: (updatedView) {
        if (mounted) {
          setState(() => view = updatedView);
        }
      },
    );
  }

  @override
  void dispose() {
    _viewListener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          widget.shortForm ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (widget.view.icon.value.isNotEmpty)
          RawEmojiIconWidget(
            emoji: widget.view.icon.toEmojiIconData(),
            emojiSize: 16,
          ),
        if (!widget.shortForm && view.icon.value.isNotEmpty) const HSpace(6),
        if (!widget.shortForm || view.icon.value.isEmpty) ...[
          Flexible(
            child: FlowyText.medium(
              view.nameOrDefault,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
