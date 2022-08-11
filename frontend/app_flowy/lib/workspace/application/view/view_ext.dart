import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
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

extension ViewExtension on ViewPB {
  Widget renderThumbnail({Color? iconColor}) {
    String thumbnail = "file_icon";

    final Widget widget = svgWidget(thumbnail, color: iconColor);
    return widget;
  }

  Plugin plugin() {
    final plugin = makePlugin(pluginType: pluginType, data: this);
    return plugin;
  }
}
