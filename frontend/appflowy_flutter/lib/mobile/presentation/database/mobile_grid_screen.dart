import 'package:flutter/material.dart';

import 'package:appflowy/mobile/presentation/base/mobile_view_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class MobileGridScreen extends StatelessWidget {
  const MobileGridScreen({
    super.key,
    required this.id,
    this.title,
    this.arguments,
  });

  /// view id
  final String id;
  final String? title;
  final Map<String, dynamic>? arguments;

  static const routeName = '/grid';
  static const viewId = 'id';
  static const viewTitle = 'title';
  static const viewArgs = 'arguments';

  @override
  Widget build(BuildContext context) {
    return MobileViewPage(
      id: id,
      title: title,
      viewLayout: ViewLayoutPB.Grid,
      arguments: arguments,
    );
  }
}
