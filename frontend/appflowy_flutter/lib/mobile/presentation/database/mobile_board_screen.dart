import 'package:appflowy/mobile/presentation/base/mobile_view_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class MobileBoardScreen extends StatelessWidget {
  static const routeName = '/board';
  static const viewId = 'id';
  static const viewTitle = 'title';

  const MobileBoardScreen({
    super.key,
    required this.id,
    this.title,
  });

  /// view id
  final String id;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return MobileViewPage(
      id: id,
      title: title,
      viewLayout: ViewLayoutPB.Document,
    );
  }
}
