import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/platform_extension.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GridMediaCellSkin extends IEditableMediaCellSkin {
  const GridMediaCellSkin({this.isMobileRowDetail = false});

  final bool isMobileRowDetail;

  @override
  void dispose() {}

  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    PopoverController popoverController,
    MediaCellBloc bloc,
  ) {
    final isMobile = PlatformExtension.isMobile;

    Widget child = BlocBuilder<MediaCellBloc, MediaCellState>(
      builder: (context, state) {
        final filesToDisplay = state.files.take(4).toList();
        final extraCount = state.files.length - filesToDisplay.length;

        final wrapContent = context.read<MediaCellBloc>().wrapContent;
        final children = <Widget>[
          ...filesToDisplay.map((file) => _FilePreviewRender(file: file)),
          if (extraCount > 0) _ExtraInfo(extraCount: extraCount),
        ];

        if (filesToDisplay.isEmpty && isMobile) {
          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                LocaleKeys.grid_row_textPlaceholder.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ),
          );
        }

        if (!isMobile && wrapContent) {
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
    );

    if (!isMobile) {
      child = AppFlowyPopover(
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
        child: child,
      );
    } else {
      child = Align(
        alignment: AlignmentDirectional.centerStart,
        child: child,
      );

      if (isMobileRowDetail) {
        child = Container(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: AlignmentDirectional.centerStart,
          child: child,
        );
      }

      child = InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showMobileBottomSheet(
            context,
            builder: (_) => BlocProvider.value(
              value: context.read<MediaCellBloc>(),
              child: const MobileMediaCellEditor(),
            ),
          );
        },
        hoverColor: Colors.transparent,
        child: child,
      );
    }

    return BlocProvider.value(
      value: bloc,
      child: Builder(builder: (context) => child),
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
          userProfilePB: context.read<MediaCellBloc>().state.userProfile,
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
        ),
        child: FlowySvg(
          file.fileType.icon,
          color: AFThemeExtension.of(context).textColor,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
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
