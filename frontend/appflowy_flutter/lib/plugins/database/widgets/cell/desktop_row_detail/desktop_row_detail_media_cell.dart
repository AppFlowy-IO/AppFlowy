import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DekstopRowDetailMediaCellSkin extends IEditableMediaCellSkin {
  final mutex = PopoverMutex();

  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    PopoverController popoverController,
    MediaCellBloc bloc,
  ) {
    return BlocProvider.value(
      value: bloc,
      child: Builder(
        builder: (context) => BlocBuilder<MediaCellBloc, MediaCellState>(
          builder: (context, state) {
            final filesToDisplay = state.files.take(4).toList();
            final extraCount = state.files.length - filesToDisplay.length;

            return SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (state.files.isEmpty) {
                    return GestureDetector(
                      onTap: () => popoverController.show(),
                      child: AppFlowyPopover(
                        mutex: mutex,
                        controller: popoverController,
                        asBarrier: true,
                        constraints: const BoxConstraints(
                          minWidth: 250,
                          maxWidth: 250,
                          maxHeight: 400,
                        ),
                        offset: const Offset(0, 10),
                        margin: EdgeInsets.zero,
                        direction: PopoverDirection.bottomWithLeftAligned,
                        popupBuilder: (_) => BlocProvider.value(
                          value: context.read<MediaCellBloc>(),
                          child: const MediaCellEditor(),
                        ),
                        onClose: () => cellContainerNotifier.isFocus = false,
                        child: FlowyHover(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: FlowyText.medium(
                              LocaleKeys.grid_row_textPlaceholder.tr(),
                              color: Theme.of(context).hintColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final size = constraints.maxWidth / 2 - 6;
                  return Wrap(
                    runSpacing: 12,
                    spacing: 12,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppFlowyPopover(
                            mutex: mutex,
                            controller: popoverController,
                            asBarrier: true,
                            constraints: const BoxConstraints(
                              minWidth: 250,
                              maxWidth: 250,
                              maxHeight: 400,
                            ),
                            offset: const Offset(0, 10),
                            margin: EdgeInsets.zero,
                            direction: PopoverDirection.bottomWithLeftAligned,
                            popupBuilder: (_) => BlocProvider.value(
                              value: context.read<MediaCellBloc>(),
                              child: const MediaCellEditor(),
                            ),
                            onClose: () =>
                                cellContainerNotifier.isFocus = false,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                              ),
                              child: FlowyHover(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const FlowySvg(FlowySvgs.edit_s),
                                      const HSpace(4),
                                      FlowyText.regular(
                                        LocaleKeys.button_edit.tr(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...filesToDisplay.map(
                        (file) => _FilePreviewRender(
                          key: ValueKey(file.id),
                          file: file,
                          size: size,
                          mutex: mutex,
                        ),
                      ),
                      if (extraCount > 0)
                        _ExtraInfo(
                          extraCount: extraCount,
                          controller: popoverController,
                          mutex: mutex,
                          cellContainerNotifier: cellContainerNotifier,
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilePreviewRender extends StatefulWidget {
  const _FilePreviewRender({
    super.key,
    required this.file,
    required this.size,
    required this.mutex,
  });

  final MediaFilePB file;
  final double size;
  final PopoverMutex mutex;

  @override
  State<_FilePreviewRender> createState() => _FilePreviewRenderState();
}

class _FilePreviewRenderState extends State<_FilePreviewRender> {
  final controller = PopoverController();

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.file.fileType == MediaFileTypePB.Image) {
      if (widget.file.uploadType == MediaUploadTypePB.NetworkMedia) {
        child = Image.network(
          widget.file.url,
          fit: BoxFit.cover,
        );
      } else if (widget.file.uploadType == MediaUploadTypePB.LocalMedia) {
        child = Image.file(
          File(widget.file.url),
          fit: BoxFit.cover,
        );
      } else {
        // Cloud
        child = FlowyNetworkImage(
          url: widget.file.url,
          userProfilePB: context.read<MediaCellBloc>().state.userProfile,
        );
      }
    } else {
      child = DecoratedBox(
        decoration: BoxDecoration(color: widget.file.fileType.color),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            child: FlowySvg(
              widget.file.fileType.icon,
              color: AFThemeExtension.of(context).strongText,
              size: const Size.square(32),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Corners.s6Radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: widget.size,
                width: widget.size,
                constraints: BoxConstraints(
                  maxHeight: widget.size < 150 ? 100 : 195,
                  minHeight: widget.size < 150 ? 100 : 195,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AFThemeExtension.of(context).greyHover,
                  borderRadius: const BorderRadius.only(
                    topLeft: Corners.s6Radius,
                    topRight: Corners.s6Radius,
                  ),
                ),
                child: child,
              ),
              Container(
                height: 28,
                width: widget.size,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).isLightMode
                      ? Theme.of(context).cardColor
                      : AFThemeExtension.of(context).greyHover,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Corners.s6Radius,
                    bottomRight: Corners.s6Radius,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(
                    child: FlowyText.medium(
                      widget.file.name,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 12,
                      color: AFThemeExtension.of(context).secondaryTextColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: AppFlowyPopover(
            key: ValueKey('menu_${widget.file.id}'),
            controller: controller,
            mutex: widget.mutex,
            asBarrier: true,
            constraints: const BoxConstraints(maxWidth: 150),
            direction: PopoverDirection.bottomWithRightAligned,
            offset: const Offset(0, 5),
            popupBuilder: (_) => BlocProvider.value(
              value: context.read<MediaCellBloc>(),
              child: MediaItemMenu(file: widget.file),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(Corners.s8Radius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: FlowyIconButton(
                  onPressed: controller.show,
                  width: 20,
                  radius: BorderRadius.circular(0),
                  icon: FlowySvg(
                    FlowySvgs.three_dots_s,
                    color: AFThemeExtension.of(context).textColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExtraInfo extends StatelessWidget {
  const _ExtraInfo({
    required this.extraCount,
    required this.controller,
    required this.mutex,
    required this.cellContainerNotifier,
  });

  final int extraCount;
  final PopoverController controller;
  final PopoverMutex mutex;
  final CellContainerNotifier cellContainerNotifier;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      key: const Key('extra_info'),
      mutex: mutex,
      controller: controller,
      triggerActions: PopoverTriggerFlags.none,
      constraints: const BoxConstraints(
        minWidth: 250,
        maxWidth: 250,
        maxHeight: 400,
      ),
      margin: EdgeInsets.zero,
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (_) => BlocProvider.value(
        value: context.read<MediaCellBloc>(),
        child: const MediaCellEditor(),
      ),
      onClose: () => cellContainerNotifier.isFocus = false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.show,
        child: FlowyHover(
          resetHoverOnRebuild: false,
          child: Container(
            height: 38,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AFThemeExtension.of(context).greyHover,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FlowyText.regular(
              LocaleKeys.grid_media_showMore.tr(args: ['$extraCount']),
              lineHeight: 1,
            ),
          ),
        ),
      ),
    );
  }
}
