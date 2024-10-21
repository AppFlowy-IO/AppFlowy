import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class ViewTabBarItem extends StatefulWidget {
  const ViewTabBarItem({super.key, required this.view});

  final ViewPB view;

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
  Widget build(BuildContext context) => FlowyText.medium(view.nameOrDefault);
}
