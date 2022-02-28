import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/image.dart';

AssetImage assetImageForViewType(ViewType type) {
  final imageName = _imageNameForViewType(type);
  return AssetImage('assets/images/$imageName');
}

extension SvgViewType on View {
  Widget thumbnail({Color? iconColor}) {
    final imageName = _imageNameForViewType(viewType);
    final Widget widget = svg(imageName, color: iconColor);
    return widget;
  }
}

String _imageNameForViewType(ViewType type) {
  switch (type) {
    case ViewType.RichText:
      return "file_icon";
    case ViewType.Plugin:
      return "file_icon";
    default:
      return "file_icon";
  }
}
