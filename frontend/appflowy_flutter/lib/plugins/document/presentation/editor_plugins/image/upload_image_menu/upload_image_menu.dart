import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/cover_editor.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsplash_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/widgets/upload_image_file_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorOption;
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'widgets/embed_image_url_widget.dart';

enum UploadImageType {
  local,
  url,
  unsplash,
  color;

  String get description => switch (this) {
        UploadImageType.local =>
          LocaleKeys.document_imageBlock_upload_label.tr(),
        UploadImageType.url =>
          LocaleKeys.document_imageBlock_embedLink_label.tr(),
        UploadImageType.unsplash =>
          LocaleKeys.document_imageBlock_unsplash_label.tr(),
        UploadImageType.color => LocaleKeys.document_plugins_cover_colors.tr(),
      };
}

class UploadImageMenu extends StatefulWidget {
  const UploadImageMenu({
    super.key,
    required this.onSelectedLocalImages,
    required this.onSelectedAIImage,
    required this.onSelectedNetworkImage,
    this.onSelectedColor,
    this.supportTypes = UploadImageType.values,
    this.limitMaximumImageSize = false,
    this.allowMultipleImages = false,
  });

  final void Function(List<XFile>) onSelectedLocalImages;
  final void Function(String url) onSelectedAIImage;
  final void Function(String url) onSelectedNetworkImage;
  final void Function(String color)? onSelectedColor;
  final List<UploadImageType> supportTypes;
  final bool limitMaximumImageSize;
  final bool allowMultipleImages;

  @override
  State<UploadImageMenu> createState() => _UploadImageMenuState();
}

class _UploadImageMenuState extends State<UploadImageMenu> {
  late final List<UploadImageType> values;
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    values = widget.supportTypes;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: values.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            onTap: (value) => setState(() {
              currentTabIndex = value;
            }),
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            overlayColor: WidgetStatePropertyAll(
              UniversalPlatform.isDesktop
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
            ),
            padding: EdgeInsets.zero,
            tabs: values.map(
              (e) {
                final child = Padding(
                  padding: EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    bottom: 8.0,
                    top: UniversalPlatform.isMobile ? 0 : 8.0,
                  ),
                  child: FlowyText(e.description),
                );
                if (UniversalPlatform.isDesktop) {
                  return FlowyHover(
                    style: const HoverStyle(borderRadius: BorderRadius.zero),
                    child: child,
                  );
                }
                return child;
              },
            ).toList(),
          ),
          const Divider(height: 2),
          _buildTab(),
        ],
      ),
    );
  }

  Widget _buildTab() {
    final constraints =
        UniversalPlatform.isMobile ? const BoxConstraints(minHeight: 92) : null;
    final type = values[currentTabIndex];
    switch (type) {
      case UploadImageType.local:
        Widget child = UploadImageFileWidget(
          allowMultipleImages: widget.allowMultipleImages,
          onPickFiles: widget.onSelectedLocalImages,
        );
        if (UniversalPlatform.isDesktop) {
          child = Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              constraints: constraints,
              child: child,
            ),
          );
        } else {
          child = Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 12.0,
            ),
            child: child,
          );
        }
        return child;

      case UploadImageType.url:
        return Container(
          padding: const EdgeInsets.all(8.0),
          constraints: constraints,
          child: EmbedImageUrlWidget(
            onSubmit: widget.onSelectedNetworkImage,
          ),
        );
      case UploadImageType.unsplash:
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: UnsplashImageWidget(
              onSelectUnsplashImage: widget.onSelectedNetworkImage,
            ),
          ),
        );
      case UploadImageType.color:
        final theme = Theme.of(context);
        final padding = UniversalPlatform.isMobile
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.all(8.0);
        return Container(
          constraints: constraints,
          padding: padding,
          alignment: Alignment.center,
          child: CoverColorPicker(
            pickerBackgroundColor: theme.cardColor,
            pickerItemHoverColor: theme.hoverColor,
            backgroundColorOptions: FlowyTint.values
                .map<ColorOption>(
                  (t) => ColorOption(
                    colorHex: t.color(context).toHex(),
                    name: t.tintName(AppFlowyEditorL10n.current),
                  ),
                )
                .toList(),
            onSubmittedBackgroundColorHex: (color) {
              widget.onSelectedColor?.call(color);
            },
          ),
        );
    }
  }
}
