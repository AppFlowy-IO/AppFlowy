import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/embed_image_url_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsplash_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_file_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

enum UploadImageType {
  local,
  url,
  unsplash,
  ai;

  String get description {
    switch (this) {
      case UploadImageType.local:
        return LocaleKeys.document_imageBlock_upload_label.tr();
      case UploadImageType.url:
        return LocaleKeys.document_imageBlock_embedLink_label.tr();
      case UploadImageType.unsplash:
        return 'Unsplash';
      case UploadImageType.ai:
        return 'Generate from AI';
    }
  }
}

class UploadImageMenu extends StatefulWidget {
  const UploadImageMenu({
    super.key,
    required this.onPickFile,
    required this.onSubmit,
  });

  final void Function(String? path) onPickFile;
  final void Function(String url) onSubmit;

  @override
  State<UploadImageMenu> createState() => _UploadImageMenuState();
}

class _UploadImageMenuState extends State<UploadImageMenu> {
  int currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // UploadImageType.values.length, // ai is not implemented yet
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            onTap: (value) => setState(() {
              currentTabIndex = value;
            }),
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            overlayColor: MaterialStatePropertyAll(
              Theme.of(context).colorScheme.secondary,
            ),
            padding: EdgeInsets.zero,
            splashBorderRadius: BorderRadius.circular(4),
            tabs: UploadImageType.values
                .where(
                  (element) => element != UploadImageType.ai,
                ) // ai is not implemented yet
                .map(
                  (e) => FlowyHover(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      child: FlowyText(e.description),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(
            height: 2,
          ),
          _buildTab(),
        ],
      ),
    );
  }

  Widget _buildTab() {
    final type = UploadImageType.values[currentTabIndex];
    switch (type) {
      case UploadImageType.local:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: UploadImageFileWidget(
            onPickFile: widget.onPickFile,
          ),
        );
      case UploadImageType.url:
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: EmbedImageUrlWidget(
            onSubmit: widget.onSubmit,
          ),
        );
      case UploadImageType.unsplash:
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: UnsplashImageWidget(
              onSelectUnsplashImage: widget.onSubmit,
            ),
          ),
        );
      case UploadImageType.ai:
        return const FlowyText.medium('ai');
    }
  }
}
