import 'package:appflowy/mobile/presentation/base/mobile_view_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class MobileCalendarScreen extends StatelessWidget {
  static const routeName = '/calendar';
  static const viewId = 'id';
  static const viewTitle = 'title';

  const MobileCalendarScreen({
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
