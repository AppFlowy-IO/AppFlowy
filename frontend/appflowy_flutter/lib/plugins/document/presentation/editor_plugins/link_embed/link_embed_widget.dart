import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_preview.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class LinkEmbedWidget extends StatelessWidget {
  const LinkEmbedWidget({
    super.key,
    required this.node,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.isHovering = false,
    this.status = LinkPreviewStatus.loading,
  });

  final Node node;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;
  final bool isHovering;
  final LinkPreviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
