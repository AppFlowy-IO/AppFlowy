import 'dart:io';

import 'package:flutter/widgets.dart';

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
          final filesToDisplay = state.files.take(4).toList();
          final extraCount = state.files.length - filesToDisplay.length;

          final wrapContent = context.read<MediaCellBloc>().wrapContent;
          final children = [
            ...filesToDisplay.map((file) => _FilePreviewRender(file: file)),
            if (extraCount > 0) _ExtraInfo(extraCount: extraCount),
          ];
          if (wrapContent) {
            return Padding(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  runSpacing: 4,
                  children: children,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SeparatedRow(
                  separatorBuilder: () => const HSpace(6),
                  children: children,
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
    Widget child;
    if (file.fileType == MediaFileTypePB.Image) {
      if (file.uploadType == MediaUploadTypePB.NetworkMedia) {
        child = Image.network(
          file.url,
          height: 32,
          width: 32,
          fit: BoxFit.cover,
        );
      } else if (file.uploadType == MediaUploadTypePB.LocalMedia) {
        child = Image.file(
          File(file.url),
          height: 32,
          width: 32,
          fit: BoxFit.cover,
        );
      } else {
        // Cloud
        child = FlowyNetworkImage(
          url: file.url,
          userProfilePB: context.read<MediaCellBloc>().userProfile,
          height: 32,
          width: 32,
        );
      }
    } else {
      child = Container(
        height: 32,
        width: 32,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AFThemeExtension.of(context).greyHover,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FlowySvg(
          file.fileType.icon,
          color: AFThemeExtension.of(context).textColor,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: child,
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
        height: 32,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AFThemeExtension.of(context).greyHover,
          borderRadius: BorderRadius.circular(4),
        ),
        child: FlowyText.regular(
          LocaleKeys.grid_media_moreFilesHint.tr(args: ['$extraCount']),
          lineHeight: 1,
        ),
      ),
    );
  }
}
