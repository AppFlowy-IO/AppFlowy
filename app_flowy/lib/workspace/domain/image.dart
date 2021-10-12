import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/image.dart';

AssetImage assetImageForViewType(ViewType type) {
  final imageName = _imageNameForViewType(type);
  return AssetImage('assets/images/$imageName');
}

extension SvgViewType on View {
  Widget thumbnail() {
    final imageName = _imageNameForViewType(viewType);
    final Widget widget = svg(imageName);
    return widget;
  }
}

String _imageNameForViewType(ViewType type) {
  switch (type) {
    case ViewType.Doc:
      return "file_icon";
    default:
      return "file_icon";
  }
}
