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
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DekstopRowDetailMediaCellSkin extends IEditableMediaCellSkin {
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
        builder: (context) => AppFlowyPopover(
          controller: popoverController,
          constraints: const BoxConstraints(
            minWidth: 250,
            maxWidth: 250,
            maxHeight: 400,
          ),
          margin: EdgeInsets.zero,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithCenterAligned,
          popupBuilder: (_) => BlocProvider.value(
            value: context.read<MediaCellBloc>(),
            child: const MediaCellEditor(),
          ),
          onClose: () => cellContainerNotifier.isFocus = false,
          child: BlocBuilder<MediaCellBloc, MediaCellState>(
            builder: (context, state) {
              final filesToDisplay = state.files.take(4).toList();
              final extraCount = state.files.length - filesToDisplay.length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (state.files.isEmpty) {
                        return Flexible(
                          child: FlowyText.medium(
                            LocaleKeys.grid_row_textPlaceholder.tr(),
                            color: Theme.of(context).hintColor,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }

                      final size = constraints.maxWidth / 2 - 8;
                      return Wrap(
                        runSpacing: 6,
                        spacing: 6,
                        children: [
                          ...filesToDisplay.map(
                            (file) =>
                                _FilePreviewRender(file: file, size: size),
                          ),
                          if (extraCount > 0)
                            _ExtraInfo(extraCount: extraCount),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilePreviewRender extends StatelessWidget {
  const _FilePreviewRender({required this.file, required this.size});

  final MediaFilePB file;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (file.fileType == MediaFileTypePB.Image) {
      if (file.uploadType == MediaUploadTypePB.NetworkMedia) {
        child = Image.network(
          file.url,
          fit: BoxFit.cover,
        );
      } else if (file.uploadType == MediaUploadTypePB.LocalMedia) {
        child = Image.file(
          File(file.url),
          fit: BoxFit.cover,
        );
      } else {
        // Cloud
        child = FlowyNetworkImage(
          url: file.url,
          userProfilePB: context.read<MediaCellBloc>().state.userProfile,
        );
      }
    } else {
      child = Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: FlowySvg(
                  file.fileType.icon,
                  color: AFThemeExtension.of(context).textColor,
                  size: const Size.square(32),
                ),
              ),
            ),
          ),
          Container(
            height: 32,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AFThemeExtension.of(context).greyHover,
              borderRadius: Corners.s6Border,
            ),
            child: Center(
              child: FlowyText.regular(
                file.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        height: size,
        width: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AFThemeExtension.of(context).greyHover,
          borderRadius: BorderRadius.circular(4),
        ),
        child: child,
      ),
    );
  }
}

class _ExtraInfo extends StatelessWidget {
  const _ExtraInfo({required this.extraCount});

  final int extraCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
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
    );
  }
}
