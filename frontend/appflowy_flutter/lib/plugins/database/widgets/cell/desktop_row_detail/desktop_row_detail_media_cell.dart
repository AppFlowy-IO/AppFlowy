import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _defaultFilesToDisplay = 5;

class DekstopRowDetailMediaCellSkin extends IEditableMediaCellSkin {
  final mutex = PopoverMutex();
  final addFileController = PopoverController();

  @override
  void dispose() {
    addFileController.close();
    mutex.dispose();
  }

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
            final filesToDisplay = state.showAllFiles
                ? state.files
                : state.files.take(_defaultFilesToDisplay).toList();
            final extraCount = state.files.length - _defaultFilesToDisplay;

            return SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (state.files.isEmpty) {
                    return _AddFileButton(
                      controller: addFileController,
                      direction: PopoverDirection.bottomWithLeftAligned,
                      mutex: mutex,
                      child: FlowyHover(
                        style: HoverStyle(
                          hoverColor:
                              AFThemeExtension.of(context).lightGreyHover,
                        ),
                        child: GestureDetector(
                          onTap: addFileController.show,
                          behavior: HitTestBehavior.translucent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
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
                      ...filesToDisplay.map(
                        (file) => _FilePreviewRender(
                          key: ValueKey(file.id),
                          file: file,
                          size: size,
                          mutex: mutex,
                        ),
                      ),
                      SizedBox(
                        width: size,
                        height: size / 2,
                        child: _AddFileButton(
                          controller: addFileController,
                          mutex: mutex,
                          child: FlowyHover(
                            resetHoverOnRebuild: false,
                            child: GestureDetector(
                              onTap: addFileController.show,
                              behavior: HitTestBehavior.translucent,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FlowySvg(
                                      FlowySvgs.add_s,
                                      size: Size.square(24),
                                    ),
                                    const VSpace(4),
                                    FlowyText(
                                      LocaleKeys.grid_media_addFileOrImage.tr(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (extraCount > 0)
                        _ShowAllFilesButton(extraCount: extraCount),
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

class _AddFileButton extends StatelessWidget {
  const _AddFileButton({
    this.mutex,
    required this.controller,
    this.direction = PopoverDirection.bottomWithCenterAligned,
    required this.child,
  });

  final PopoverController controller;
  final PopoverMutex? mutex;
  final PopoverDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      triggerActions: PopoverTriggerFlags.none,
      controller: controller,
      mutex: mutex,
      offset: const Offset(0, 10),
      direction: direction,
      popupBuilder: (_) => FileUploadMenu(
        onInsertLocalFile: (file) => insertLocalFile(
          context,
          file,
          userProfile: context.read<MediaCellBloc>().state.userProfile,
          documentId: context.read<MediaCellBloc>().rowId,
          onUploadSuccess: (path, isLocalMode) {
            final mediaCellBloc = context.read<MediaCellBloc>();
            if (mediaCellBloc.isClosed) {
              return;
            }

            mediaCellBloc.add(
              MediaCellEvent.addFile(
                url: path,
                name: file.name,
                uploadType: isLocalMode
                    ? FileUploadTypePB.LocalFile
                    : FileUploadTypePB.CloudFile,
                fileType: file.fileType.toMediaFileTypePB(),
              ),
            );

            controller.close();
          },
        ),
        onInsertNetworkFile: (url) {
          if (url.isEmpty) return;
          final uri = Uri.tryParse(url);
          if (uri == null) {
            return;
          }

          final fakeFile = XFile(uri.path);
          MediaFileTypePB fileType = fakeFile.fileType.toMediaFileTypePB();
          fileType = fileType == MediaFileTypePB.Other
              ? MediaFileTypePB.Link
              : fileType;

          String name =
              uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "";
          if (name.isEmpty && uri.pathSegments.length > 1) {
            name = uri.pathSegments[uri.pathSegments.length - 2];
          } else if (name.isEmpty) {
            name = uri.host;
          }

          context.read<MediaCellBloc>().add(
                MediaCellEvent.addFile(
                  url: url,
                  name: name,
                  uploadType: FileUploadTypePB.NetworkFile,
                  fileType: fileType,
                ),
              );

          controller.close();
        },
      ),
      child: child,
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
  final nameController = TextEditingController();
  final errorMessage = ValueNotifier<String?>(null);
  final controller = PopoverController();
  bool isHovering = false;
  bool isSelected = false;

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.file.fileType == MediaFileTypePB.Image) {
      child = AFImage(
        url: widget.file.url,
        uploadType: widget.file.uploadType,
        userProfile: context.read<MediaCellBloc>().state.userProfile,
      );
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

    return AppFlowyPopover(
      controller: controller,
      constraints: const BoxConstraints(maxWidth: 150),
      offset: const Offset(0, 5),
      onClose: () => setState(() => isSelected = false),
      popupBuilder: (_) => SeparatedColumn(
        separatorBuilder: () => const VSpace(4),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.file.fileType == MediaFileTypePB.Image) ...[
            FlowyButton(
              onTap: () {
                controller.close();
                showDialog(
                  context: context,
                  builder: (_) => InteractiveImageViewer(
                    userProfile:
                        context.read<MediaCellBloc>().state.userProfile,
                    imageProvider: AFBlockImageProvider(
                      images: [
                        ImageBlockData(
                          url: widget.file.url,
                          type: widget.file.uploadType.toCustomImageType(),
                        ),
                      ],
                      onDeleteImage: (_) => context
                          .read<MediaCellBloc>()
                          .deleteFile(widget.file.id),
                    ),
                  ),
                );
              },
              leftIcon: FlowySvg(
                FlowySvgs.full_view_s,
                color: Theme.of(context).iconTheme.color,
                size: const Size.square(18),
              ),
              text: FlowyText.regular(
                LocaleKeys.settings_files_open.tr(),
                color: AFThemeExtension.of(context).textColor,
              ),
              leftIconSize: const Size(18, 18),
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
            ),
          ],
          FlowyButton(
            leftIcon: FlowySvg(
              FlowySvgs.edit_s,
              color: Theme.of(context).iconTheme.color,
            ),
            text: FlowyText.regular(
              LocaleKeys.grid_media_rename.tr(),
              color: AFThemeExtension.of(context).textColor,
            ),
            onTap: () {
              controller.close();

              nameController.text = widget.file.name;
              nameController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: nameController.text.length,
              );

              showCustomConfirmDialog(
                context: context,
                title: LocaleKeys.document_plugins_file_renameFile_title.tr(),
                description: LocaleKeys
                    .document_plugins_file_renameFile_description
                    .tr(),
                closeOnConfirm: false,
                builder: (dialogContext) => FileRenameTextField(
                  nameController: nameController,
                  errorMessage: errorMessage,
                  onSubmitted: () => _saveName(context),
                  disposeController: false,
                ),
                confirmLabel: LocaleKeys.button_save.tr(),
                onConfirm: () => _saveName(context),
              );
            },
          ),
          FlowyButton(
            onTap: () async => downloadMediaFile(
              context,
              widget.file,
              userProfile: context.read<MediaCellBloc>().state.userProfile,
            ),
            leftIcon: FlowySvg(
              FlowySvgs.download_s,
              color: Theme.of(context).iconTheme.color,
              size: const Size.square(18),
            ),
            text: FlowyText.regular(
              LocaleKeys.button_download.tr(),
              color: AFThemeExtension.of(context).textColor,
            ),
            leftIconSize: const Size(18, 18),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
          ),
          FlowyButton(
            onTap: () {
              controller.close();
              showConfirmDeletionDialog(
                context: context,
                name: widget.file.name,
                description: LocaleKeys.grid_media_deleteFileDescription.tr(),
                onConfirm: () => context
                    .read<MediaCellBloc>()
                    .add(MediaCellEvent.removeFile(fileId: widget.file.id)),
              );
            },
            leftIcon: FlowySvg(
              FlowySvgs.delete_s,
              color: Theme.of(context).colorScheme.error,
              size: const Size.square(18),
            ),
            text: FlowyText.regular(
              LocaleKeys.button_delete.tr(),
              color: Theme.of(context).colorScheme.error,
            ),
            leftIconSize: const Size(18, 18),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.file.fileType != MediaFileTypePB.Image
            ? null
            : () => openInteractiveViewerFromFile(
                  context,
                  widget.file,
                  userProfile: context.read<MediaCellBloc>().state.userProfile,
                  onDeleteImage: (_) =>
                      context.read<MediaCellBloc>().deleteFile(widget.file.id),
                ),
        child: FlowyHover(
          isSelected: () => isSelected,
          resetHoverOnRebuild: false,
          onHover: (hovering) => setState(() => isHovering = hovering),
          child: Stack(
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
                            color:
                                AFThemeExtension.of(context).secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isHovering || isSelected)
                Positioned(
                  top: 5,
                  right: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.all(Corners.s8Radius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: FlowyIconButton(
                        onPressed: () {
                          setState(() => isSelected = true);
                          controller.show();
                        },
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
            ],
          ),
        ),
      ),
    );
  }

  void _saveName(BuildContext context) {
    final newName = nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    context
        .read<MediaCellBloc>()
        .add(MediaCellEvent.renameFile(fileId: widget.file.id, name: newName));
    Navigator.of(context).pop();
  }
}

class _ShowAllFilesButton extends StatelessWidget {
  const _ShowAllFilesButton({required this.extraCount});

  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final show = context.read<MediaCellBloc>().state.showAllFiles;

    final label = show
        ? extraCount == 1
            ? LocaleKeys.grid_media_hideFile.tr()
            : LocaleKeys.grid_media_hideFiles.tr(args: ['$extraCount'])
        : extraCount == 1
            ? LocaleKeys.grid_media_showFile.tr()
            : LocaleKeys.grid_media_showFiles.tr(args: ['$extraCount']);

    final quarterTurns = show ? 1 : 3;

    return SizedBox(
      height: 30,
      child: FlowyButton(
        text: FlowyText.medium(
          label,
          lineHeight: 1.0,
          color: Theme.of(context).hintColor,
        ),
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        leftIcon: RotatedBox(
          quarterTurns: quarterTurns,
          child: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).hintColor,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        onTap: () => context
            .read<MediaCellBloc>()
            .add(const MediaCellEvent.toggleShowAllFiles()),
      ),
    );
  }
}
