import 'dart:io';

import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DekstopGridMediaCellSkin extends IEditableMediaCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    PopoverController popoverController,
    MediaCellBloc bloc,
  ) {
    return AppFlowyPopover(
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
          final wrapContent = context.read<MediaCellBloc>().wrapContent;
          if (wrapContent) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: IntrinsicWidth(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: state.files
                      .map((file) => _FilePreviewRender(file: file))
                      .toList(),
                ),
              ),
            );
          }

          return FlowyTooltip(
            message: '${state.files.length} files - click to view',
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IntrinsicWidth(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SeparatedRow(
                    separatorBuilder: () => const HSpace(6),
                    children: state.files
                        .map((file) => _FilePreviewRender(file: file))
                        .toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilePreviewRender extends StatelessWidget {
  const _FilePreviewRender({required this.file});

  final MediaFilePB file;

  @override
  Widget build(BuildContext context) {
    if (file.fileType == MediaFileTypePB.Image) {
      if (file.uploadType == MediaUploadTypePB.NetworkMedia) {
        return Image.network(file.url, height: 32);
      } else if (file.uploadType == MediaUploadTypePB.LocalMedia) {
        return Image.file(File(file.url), height: 32);
      } else {
        // Cloud
        return FlowyNetworkImage(
          url: file.url,
          userProfilePB: context.read<MediaCellBloc>().userProfile,
          height: 32,
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AFThemeExtension.of(context).greyHover,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlowyText(
        file.name,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
