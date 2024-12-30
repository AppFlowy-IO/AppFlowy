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
    this.blockId,
  });

  /// view id
  final String id;
  final String? title;
  final bool showMoreButton;
  final String? fixedTitle;
  final String? blockId;

  static const routeName = '/docs';
  static const viewId = 'id';
  static const viewTitle = 'title';
  static const viewShowMoreButton = 'show_more_button';
  static const viewFixedTitle = 'fixed_title';
  static const viewBlockId = 'block_id';

  @override
  Widget build(BuildContext context) {
    return MobileViewPage(
      id: id,
      title: title,
      viewLayout: ViewLayoutPB.Document,
      showMoreButton: showMoreButton,
      fixedTitle: fixedTitle,
      blockId: blockId,
    );
  }
}
