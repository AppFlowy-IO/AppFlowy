import 'package:appflowy/mobile/presentation/base/mobile_view_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';

class MobileDocumentScreen extends StatelessWidget {
  const MobileDocumentScreen({
    super.key,
    required this.id,
    this.title,
    this.showMoreButton = true,
    this.fixedTitle,
  });

  /// view id
  final String id;
  final String? title;
  final bool showMoreButton;
  final String? fixedTitle;

  static const routeName = '/docs';
  static const viewId = 'id';
  static const viewTitle = 'title';
  static const viewShowMoreButton = 'show_more_button';
  static const viewFixedTitle = 'fixed_title';

  @override
  Widget build(BuildContext context) {
    return MobileViewPage(
      id: id,
      title: title,
      viewLayout: ViewLayoutPB.Document,
      showMoreButton: showMoreButton,
      fixedTitle: fixedTitle,
    );
  }
}
