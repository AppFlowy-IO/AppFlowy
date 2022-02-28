import 'package:flowy_infra/image.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/material.dart';

enum FlowyPlugin {
  editor,
  kanban,
}

extension FlowyPluginExtension on FlowyPlugin {
  String displayName() {
    switch (this) {
      case FlowyPlugin.editor:
        return "Doc";
      case FlowyPlugin.kanban:
        return "Kanban";
      default:
        return "";
    }
  }

  bool enable() {
    switch (this) {
      case FlowyPlugin.editor:
        return true;
      case FlowyPlugin.kanban:
        return false;
      default:
        return false;
    }
  }
}

extension ViewExtension on View {
  Widget renderThumbnail({Color? iconColor}) {
    String thumbnail = this.thumbnail;
    if (thumbnail.isEmpty) {
      thumbnail = "file_icon";
    }

    final Widget widget = svg(thumbnail, color: iconColor);
    return widget;
  }
}
