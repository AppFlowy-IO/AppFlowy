import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';

AssetImage assetImageForViewType(ViewType type) {
  final imageName = imageNameForViewType(type);
  return AssetImage('assets/images/$imageName');
}

String imageNameForViewType(ViewType type) {
  switch (type) {
    case ViewType.Doc:
      return "file_icon.jpg";
    default:
      return "file_icon.jpg";
  }
}
