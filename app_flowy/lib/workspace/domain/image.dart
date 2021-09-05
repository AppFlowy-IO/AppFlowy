import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/image.dart';

AssetImage assetImageForViewType(ViewType type) {
  final imageName = imageNameForViewType(type);
  return AssetImage('assets/images/$imageName');
}

Widget svgImageForViewType(ViewType type) {
  final imageName = imageNameForViewType(type);
  final Widget svg = svgWidgetWithName(imageName);

  return svg;
}

String imageNameForViewType(ViewType type) {
  switch (type) {
    case ViewType.Doc:
      return "file_icon.svg";
    default:
      return "file_icon.svg";
  }
}
