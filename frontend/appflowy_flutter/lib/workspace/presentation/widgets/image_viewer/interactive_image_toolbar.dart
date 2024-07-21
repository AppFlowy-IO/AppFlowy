import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/separated_flex.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class InteractiveImageToolbar extends StatelessWidget {
  const InteractiveImageToolbar({
    super.key,
    required this.currentImage,
    required this.imageCount,
    required this.isFirstIndex,
    required this.isLastIndex,
    required this.currentScale,
    required this.onPrevious,
    required this.onNext,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final ImageBlockData currentImage;
  final int imageCount;
  final bool isFirstIndex;
  final bool isLastIndex;
  final int currentScale;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageCount > 1)
                _renderToolbarItems(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isFirstIndex) {
                          onPrevious();
                        }
                      },
                      child: FlowyTooltip(
                        message: LocaleKeys
                            .document_imageBlock_interactiveViewer_toolbar_previousImageTooltip
                            .tr(),
                        child: FlowyHover(
                          resetHoverOnRebuild: false,
                          style: HoverStyle(
                            hoverColor: isFirstIndex
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FlowySvg(
                              FlowySvgs.arrow_left_s,
                              color: isFirstIndex ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (!isLastIndex) {
                          onNext();
                        }
                      },
                      child: FlowyTooltip(
                        message: LocaleKeys
                            .document_imageBlock_interactiveViewer_toolbar_nextImageTooltip
                            .tr(),
                        child: FlowyHover(
                          resetHoverOnRebuild: false,
                          style: HoverStyle(
                            hoverColor: isLastIndex
                                ? Colors.transparent
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FlowySvg(
                              FlowySvgs.arrow_right_s,
                              color: isLastIndex ? Colors.grey : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onZoomOut,
                    child: FlowyTooltip(
                      message: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_zoomOutTooltip
                          .tr(),
                      child: FlowyHover(
                        resetHoverOnRebuild: false,
                        style: HoverStyle(
                          hoverColor: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: FlowySvg(
                            FlowySvgs.minus_s,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  FlowyTooltip(
                    message: LocaleKeys
                        .document_imageBlock_interactiveViewer_toolbar_changeZoomLevelTooltip
                        .tr(),
                    child: FlowyHover(
                      resetHoverOnRebuild: false,
                      style: HoverStyle(
                        hoverColor: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: SizedBox(
                          width: 40,
                          child: Center(
                            child: FlowyText(
                              LocaleKeys
                                  .document_imageBlock_interactiveViewer_toolbar_scalePercentage
                                  .tr(args: [currentScale.toString()]),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onZoomIn,
                    child: FlowyTooltip(
                      message: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_zoomInTooltip
                          .tr(),
                      child: FlowyHover(
                        resetHoverOnRebuild: false,
                        style: HoverStyle(
                          hoverColor: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: FlowySvg(
                            FlowySvgs.add_s,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _locateOrDownloadImage,
                    child: FlowyTooltip(
                      message: currentImage.isNotInternal
                          ? LocaleKeys
                              .document_imageBlock_interactiveViewer_toolbar_openLocalImage
                              .tr()
                          : LocaleKeys
                              .document_imageBlock_interactiveViewer_toolbar_downloadImage
                              .tr(),
                      child: FlowyHover(
                        resetHoverOnRebuild: false,
                        style: HoverStyle(
                          hoverColor: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FlowySvg(
                            currentImage.isNotInternal
                                ? currentImage.isLocal
                                    ? FlowySvgs.folder_m
                                    : FlowySvgs.m_aa_link_s
                                : FlowySvgs.import_s,
                            size: const Size.square(16),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: FlowyTooltip(
                      message: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_closeViewer
                          .tr(),
                      child: FlowyHover(
                        resetHoverOnRebuild: false,
                        style: HoverStyle(
                          hoverColor: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: FlowySvg(
                            FlowySvgs.close_s,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderToolbarItems({required List<Widget> children}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.black.withOpacity(0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SeparatedRow(
          separatorBuilder: () => const HSpace(4),
          children: children,
        ),
      ),
    );
  }

  Future<void> _locateOrDownloadImage() async {
    if (currentImage.isLocal) {
      /// If the image type is local, we simply open the image
      await afLaunchUrl(Uri.file(currentImage.url));
    } else if (currentImage.isNotInternal) {
      // In case of eg. Unsplash images (images without extension type in URL),
      // we don't know their mimetype. In the future we can write a parser
      // using the Mime package and read the image to get the proper extension.
      await afLaunchUrl(Uri.parse(currentImage.url));
    } else {
      final uri = Uri.parse(currentImage.url);
      final imgFile = File(uri.pathSegments.last);
      final savePath = await FilePicker().saveFile(
        fileName: basename(imgFile.path),
      );

      if (savePath != null) {
        final uri = Uri.parse(currentImage.url);
        final imgResponse = await http.get(uri);
        final imgFile = File(savePath);
        imgFile.writeAsBytesSync(imgResponse.bodyBytes);
      }
    }
  }
}
