import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/embed_image_url_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/open_ai_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/stability_ai_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsplash_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_file_widget.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

enum UploadImageType {
  local,
  url,
  unsplash,
  stabilityAI,
  openAI;

  String get description {
    switch (this) {
      case UploadImageType.local:
        return LocaleKeys.document_imageBlock_upload_label.tr();
      case UploadImageType.url:
        return LocaleKeys.document_imageBlock_embedLink_label.tr();
      case UploadImageType.unsplash:
        return 'Unsplash';
      case UploadImageType.openAI:
        return LocaleKeys.document_imageBlock_ai_label.tr();
      case UploadImageType.stabilityAI:
        return LocaleKeys.document_imageBlock_stability_ai_label.tr();
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
  List<UploadImageType> values = UploadImageType.values;
  bool supportOpenAI = false;
  bool supportStabilityAI = false;

  @override
  void initState() {
    super.initState();

    UserBackendService.getCurrentUserProfile().then(
      (value) {
        final supportOpenAI = value.fold(
          (l) => false,
          (r) => r.openaiKey.isNotEmpty,
        );
        final supportStabilityAI = value.fold(
          (l) => false,
          (r) => r.stabilityAiKey.isNotEmpty,
        );
        if (supportOpenAI != this.supportOpenAI ||
            supportStabilityAI != this.supportStabilityAI) {
          setState(() {
            this.supportOpenAI = supportOpenAI;
            this.supportStabilityAI = supportStabilityAI;
          });
        }
      },
    );
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
            overlayColor: MaterialStatePropertyAll(
              Theme.of(context).colorScheme.secondary,
            ),
            padding: EdgeInsets.zero,
            // splashBorderRadius: BorderRadius.circular(4),
            tabs: values
                .map(
                  (e) => FlowyHover(
                    style: const HoverStyle(borderRadius: BorderRadius.zero),
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
      case UploadImageType.openAI:
        return supportOpenAI
            ? Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OpenAIImageWidget(
                    onSelectNetworkImage: widget.onSubmit,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlowyText(
                  LocaleKeys.document_imageBlock_pleaseInputYourOpenAIKey.tr(),
                ),
              );
      case UploadImageType.stabilityAI:
        return supportStabilityAI
            ? Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: StabilityAIImageWidget(
                    onSelectImage: widget.onPickFile,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlowyText(
                  LocaleKeys.document_imageBlock_pleaseInputYourStabilityAIKey
                      .tr(),
                ),
              );
    }
  }
}
