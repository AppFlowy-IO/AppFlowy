import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
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
    required this.onScaleChanged,
    this.onDelete,
    this.userProfile,
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
  final Function(double scale) onScaleChanged;
  final UserProfilePB? userProfile;
  final VoidCallback? onDelete;

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
                    _ToolbarItem(
                      isDisabled: isFirstIndex,
                      tooltip: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_previousImageTooltip
                          .tr(),
                      icon: FlowySvgs.arrow_left_s,
                      onTap: () {
                        if (!isFirstIndex) {
                          onPrevious();
                        }
                      },
                    ),
                    _ToolbarItem(
                      isDisabled: isLastIndex,
                      tooltip: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_nextImageTooltip
                          .tr(),
                      icon: FlowySvgs.arrow_right_s,
                      onTap: () {
                        if (!isLastIndex) {
                          onNext();
                        }
                      },
                    ),
                  ],
                ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  _ToolbarItem(
                    tooltip: LocaleKeys
                        .document_imageBlock_interactiveViewer_toolbar_zoomOutTooltip
                        .tr(),
                    icon: FlowySvgs.minus_s,
                    onTap: onZoomOut,
                  ),
                  AppFlowyPopover(
                    offset: const Offset(0, -8),
                    decorationColor: Colors.transparent,
                    direction: PopoverDirection.topWithCenterAligned,
                    constraints: const BoxConstraints(maxHeight: 50),
                    popupBuilder: (context) => _renderToolbarItems(
                      children: [
                        _ScaleSlider(
                          currentScale: currentScale,
                          onScaleChanged: onScaleChanged,
                        ),
                      ],
                    ),
                    child: FlowyTooltip(
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
                  ),
                  _ToolbarItem(
                    tooltip: LocaleKeys
                        .document_imageBlock_interactiveViewer_toolbar_zoomInTooltip
                        .tr(),
                    icon: FlowySvgs.add_s,
                    onTap: onZoomIn,
                  ),
                ],
              ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  if (onDelete != null)
                    _ToolbarItem(
                      tooltip: LocaleKeys
                          .document_imageBlock_interactiveViewer_toolbar_deleteImageTooltip
                          .tr(),
                      icon: FlowySvgs.delete_s,
                      onTap: () {
                        onDelete!();
                        Navigator.of(context).pop();
                      },
                    ),
                  if (!PlatformExtension.isMobile) ...[
                    _ToolbarItem(
                      tooltip: currentImage.isNotInternal
                          ? LocaleKeys
                              .document_imageBlock_interactiveViewer_toolbar_openLocalImage
                              .tr()
                          : LocaleKeys
                              .document_imageBlock_interactiveViewer_toolbar_downloadImage
                              .tr(),
                      icon: currentImage.isNotInternal
                          ? currentImage.isLocal
                              ? FlowySvgs.folder_m
                              : FlowySvgs.m_aa_link_s
                          : FlowySvgs.download_s,
                      onTap: () => _locateOrDownloadImage(context),
                    ),
                  ],
                ],
              ),
              const HSpace(10),
              _renderToolbarItems(
                children: [
                  _ToolbarItem(
                    tooltip: LocaleKeys
                        .document_imageBlock_interactiveViewer_toolbar_closeViewer
                        .tr(),
                    icon: FlowySvgs.close_viewer_s,
                    onTap: () => Navigator.of(context).pop(),
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
          mainAxisSize: MainAxisSize.min,
          separatorBuilder: () => const HSpace(4),
          children: children,
        ),
      ),
    );
  }

  Future<void> _locateOrDownloadImage(BuildContext context) async {
    if (currentImage.isLocal) {
      /// If the image type is local, we simply open the image
      await afLaunchUrl(Uri.file(currentImage.url));
    } else if (currentImage.isNotInternal) {
      // In case of eg. Unsplash images (images without extension type in URL),
      // we don't know their mimetype. In the future we can write a parser
      // using the Mime package and read the image to get the proper extension.
      await afLaunchUrl(Uri.parse(currentImage.url));
    } else {
      if (userProfile == null) {
        return showSnapBar(
          context,
          LocaleKeys.document_plugins_image_imageDownloadFailedToken.tr(),
        );
      }

      final uri = Uri.parse(currentImage.url);
      final imgFile = File(uri.pathSegments.last);
      final savePath = await FilePicker().saveFile(
        fileName: basename(imgFile.path),
      );

      if (savePath != null) {
        final uri = Uri.parse(currentImage.url);

        final token = jsonDecode(userProfile!.token)['access_token'];
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final imgFile = File(savePath);
          await imgFile.writeAsBytes(response.bodyBytes);
        } else if (context.mounted) {
          showSnapBar(
            context,
            LocaleKeys.document_plugins_image_imageDownloadFailed.tr(),
          );
        }
      }
    }
  }
}

class _ToolbarItem extends StatelessWidget {
  const _ToolbarItem({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  final String tooltip;
  final FlowySvgData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FlowyTooltip(
        message: tooltip,
        child: FlowyHover(
          resetHoverOnRebuild: false,
          style: HoverStyle(
            hoverColor:
                isDisabled ? Colors.transparent : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(8),
            child: FlowySvg(
              icon,
              color: isDisabled ? Colors.grey : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScaleSlider extends StatefulWidget {
  const _ScaleSlider({
    required this.currentScale,
    required this.onScaleChanged,
  });

  final int currentScale;
  final Function(double scale) onScaleChanged;

  @override
  State<_ScaleSlider> createState() => __ScaleSliderState();
}

class __ScaleSliderState extends State<_ScaleSlider> {
  late int _currentScale = widget.currentScale;

  @override
  Widget build(BuildContext context) {
    return Slider(
      max: 5.0,
      min: 0.5,
      value: _currentScale / 100,
      onChanged: (scale) {
        widget.onScaleChanged(scale);
        setState(
          () => _currentScale = (scale * 100).toInt(),
        );
      },
    );
  }
}
