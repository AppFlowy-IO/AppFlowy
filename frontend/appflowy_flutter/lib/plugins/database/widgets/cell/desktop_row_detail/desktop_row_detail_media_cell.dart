import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/row/row_detail_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

const _dropFileKey = 'files_media';
const _itemWidth = 86.4;

class DekstopRowDetailMediaCellSkin extends IEditableMediaCellSkin {
  final mutex = PopoverMutex();

  @override
  void dispose() {
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
      child: BlocBuilder<MediaCellBloc, MediaCellState>(
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            if (state.files.isEmpty) {
              return _AddFileButton(
                controller: popoverController,
                direction: PopoverDirection.bottomWithLeftAligned,
                mutex: mutex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: FlowyText(
                    LocaleKeys.grid_row_textPlaceholder.tr(),
                    color: Theme.of(context).hintColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }

            int itemsToShow = state.showAllFiles ? state.files.length : 0;
            if (!state.showAllFiles) {
              // The row width is surrounded by 8px padding on each side
              final rowWidth = constraints.maxWidth - 16;

              // Each item needs 94.4 px to render, 86.4px width + 8px runSpacing
              final itemsPerRow = rowWidth ~/ (_itemWidth + 8);

              // We show at most 2 rows
              itemsToShow = itemsPerRow * 2;
            }

            final filesToDisplay =
                state.showAllFiles || itemsToShow >= state.files.length
                    ? state.files
                    : state.files.take(itemsToShow - 1).toList();
            final extraCount = state.files.length - itemsToShow;
            final images = state.files
                .where((f) => f.fileType == MediaFileTypePB.Image)
                .toList();

            final size = constraints.maxWidth / 2 - 6;
            return _AddFileButton(
              controller: popoverController,
              mutex: mutex,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ReorderableWrap(
                      needsLongPressDraggable: false,
                      runSpacing: 8,
                      spacing: 8,
                      onReorder: (from, to) => context
                          .read<MediaCellBloc>()
                          .add(MediaCellEvent.reorderFiles(from: from, to: to)),
                      footer: extraCount > 0 && !state.showAllFiles
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _toggleShowAllFiles(context),
                              child: _FilePreviewRender(
                                key: ValueKey(state.files[itemsToShow - 1].id),
                                file: state.files[itemsToShow - 1],
                                index: 9,
                                images: images,
                                size: size,
                                mutex: mutex,
                                hideFileNames: state.hideFileNames,
                                foregroundText: LocaleKeys.grid_media_extraCount
                                    .tr(args: [extraCount.toString()]),
                              ),
                            )
                          : null,
                      buildDraggableFeedback: (_, __, child) =>
                          BlocProvider.value(
                        value: context.read<MediaCellBloc>(),
                        child: _FilePreviewFeedback(child: child),
                      ),
                      children: filesToDisplay
                          .mapIndexed(
                            (index, file) => _FilePreviewRender(
                              key: ValueKey(file.id),
                              file: file,
                              index: index,
                              images: images,
                              size: size,
                              mutex: mutex,
                              hideFileNames: state.hideFileNames,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FlowySvg(
                          FlowySvgs.add_thin_s,
                          size: Size.square(12),
                        ),
                        const HSpace(6),
                        FlowyText.medium(
                          LocaleKeys.grid_media_addFileOrImage.tr(),
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                          figmaLineHeight: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggleShowAllFiles(BuildContext context) {
    context
        .read<MediaCellBloc>()
        .add(const MediaCellEvent.toggleShowAllFiles());
  }
}

class _FilePreviewFeedback extends StatelessWidget {
  const _FilePreviewFeedback({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          width: 2,
          color: const Color(0xFF00BCF0),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1F2329).withOpacity(.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: BlocProvider.value(
          value: context.read<MediaCellBloc>(),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
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
      constraints: const BoxConstraints(maxWidth: 350),
      margin: EdgeInsets.zero,
      onClose: () =>
          context.read<EditorDropManagerState>().remove(_dropFileKey),
      popupBuilder: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<EditorDropManagerState>().add(_dropFileKey);
        });

        return FileUploadMenu(
          allowMultipleFiles: true,
          onInsertLocalFile: (files) => insertLocalFiles(
            context,
            files,
            userProfile: context.read<MediaCellBloc>().state.userProfile,
            documentId: context.read<MediaCellBloc>().rowId,
            onUploadSuccess: (file, path, isLocalMode) {
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
        );
      },
      child: GestureDetector(
        onTap: controller.show,
        behavior: HitTestBehavior.translucent,
        child: FlowyHover(resetHoverOnRebuild: false, child: child),
      ),
    );
  }
}

class _FilePreviewRender extends StatefulWidget {
  const _FilePreviewRender({
    super.key,
    required this.file,
    required this.images,
    required this.index,
    required this.size,
    required this.mutex,
    this.hideFileNames = false,
    this.foregroundText,
  });

  final MediaFilePB file;
  final List<MediaFilePB> images;
  final int index;
  final double size;
  final PopoverMutex mutex;
  final bool hideFileNames;
  final String? foregroundText;

  @override
  State<_FilePreviewRender> createState() => _FilePreviewRenderState();
}

class _FilePreviewRenderState extends State<_FilePreviewRender> {
  final nameController = TextEditingController();
  final controller = PopoverController();
  bool isHovering = false;
  bool isSelected = false;

  late int thisIndex;

  MediaFilePB get file => widget.file;

  @override
  void initState() {
    super.initState();
    thisIndex = widget.images.indexOf(file);
  }

  @override
  void dispose() {
    nameController.dispose();
    controller.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FilePreviewRender oldWidget) {
    thisIndex = widget.images.indexOf(file);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (file.fileType == MediaFileTypePB.Image) {
      child = AFImage(
        url: file.url,
        uploadType: file.uploadType,
        userProfile: context.read<MediaCellBloc>().state.userProfile,
        width: _itemWidth,
        borderRadius: BorderRadius.only(
          topLeft: Corners.s5Radius,
          topRight: Corners.s5Radius,
          bottomLeft: widget.hideFileNames ? Corners.s5Radius : Radius.zero,
          bottomRight: widget.hideFileNames ? Corners.s5Radius : Radius.zero,
        ),
      );
    } else {
      child = DecoratedBox(
        decoration: BoxDecoration(color: file.fileType.color),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FlowySvg(
              file.fileType.icon,
              color: const Color(0xFF666D76),
            ),
          ),
        ),
      );
    }

    if (widget.foregroundText != null) {
      child = Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
              child: child,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: FlowyText.semibold(
                widget.foregroundText!,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: FlowyTooltip(
        message: file.name,
        child: AppFlowyPopover(
          controller: controller,
          constraints: const BoxConstraints(maxWidth: 240),
          offset: const Offset(0, 5),
          triggerActions: PopoverTriggerFlags.none,
          onClose: () => setState(() => isSelected = false),
          popupBuilder: (popoverContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<RowDetailBloc>()),
              BlocProvider.value(value: context.read<MediaCellBloc>()),
            ],
            child: _FileMenu(
              parentContext: context,
              index: thisIndex,
              file: file,
              images: widget.images,
              controller: controller,
              nameController: nameController,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.foregroundText != null
                ? null
                : () {
                    if (file.fileType != MediaFileTypePB.Image) {
                      afLaunchUrlString(widget.file.url);
                      return;
                    }

                    openInteractiveViewerFromFiles(
                      context,
                      widget.images,
                      userProfile:
                          context.read<MediaCellBloc>().state.userProfile,
                      initialIndex: thisIndex,
                      onDeleteImage: (index) {
                        final deleteFile = widget.images[index];
                        context.read<MediaCellBloc>().deleteFile(deleteFile.id);
                      },
                    );
                  },
            child: Container(
              width: _itemWidth,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Corners.s6Radius),
                border: Border.all(color: Theme.of(context).dividerColor),
                color: Theme.of(context).cardColor,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 68, child: child),
                      if (!widget.hideFileNames)
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: FlowyText(
                                  file.name,
                                  fontSize: 10,
                                  overflow: TextOverflow.ellipsis,
                                  figmaLineHeight: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (widget.foregroundText == null &&
                      (isHovering || isSelected))
                    Positioned(
                      top: 3,
                      right: 3,
                      child: FlowyIconButton(
                        onPressed: () {
                          setState(() => isSelected = true);
                          controller.show();
                        },
                        fillColor: Colors.black.withOpacity(0.4),
                        width: 18,
                        radius: BorderRadius.circular(4),
                        icon: const FlowySvg(
                          FlowySvgs.three_dots_s,
                          color: Colors.white,
                          size: Size.square(16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileMenu extends StatefulWidget {
  const _FileMenu({
    required this.parentContext,
    required this.index,
    required this.file,
    required this.images,
    required this.controller,
    required this.nameController,
  });

  /// Parent [BuildContext] used to retrieve the [MediaCellBloc]
  final BuildContext parentContext;

  /// Index of this file in [widget.images]
  final int index;

  /// The current [MediaFilePB] being previewed
  final MediaFilePB file;

  /// All images in the field, excluding non-image files-
  final List<MediaFilePB> images;

  /// The [PopoverController] to close the popover
  final PopoverController controller;

  /// The [TextEditingController] for renaming the file
  final TextEditingController nameController;

  @override
  State<_FileMenu> createState() => _FileMenuState();
}

class _FileMenuState extends State<_FileMenu> {
  final errorMessage = ValueNotifier<String?>(null);

  @override
  void dispose() {
    errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const VSpace(8),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.file.fileType == MediaFileTypePB.Image) ...[
          MediaMenuItem(
            onTap: () {
              widget.controller.close();
              _showInteractiveViewer(context);
            },
            icon: FlowySvgs.full_view_s,
            label: LocaleKeys.grid_media_expand.tr(),
          ),
          MediaMenuItem(
            onTap: () {
              widget.controller.close();
              _setCover(context);
            },
            icon: FlowySvgs.cover_s,
            label: LocaleKeys.grid_media_setAsCover.tr(),
          ),
        ],
        MediaMenuItem(
          onTap: () {
            widget.controller.close();
            afLaunchUrlString(widget.file.url);
          },
          icon: FlowySvgs.open_in_browser_s,
          label: LocaleKeys.grid_media_openInBrowser.tr(),
        ),
        MediaMenuItem(
          onTap: () {
            widget.controller.close();
            widget.nameController.text = widget.file.name;
            widget.nameController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: widget.nameController.text.length,
            );

            _showRenameConfirmDialog();
          },
          icon: FlowySvgs.rename_s,
          label: LocaleKeys.grid_media_rename.tr(),
        ),
        if (widget.file.uploadType == FileUploadTypePB.CloudFile) ...[
          MediaMenuItem(
            onTap: () async => downloadMediaFile(
              context,
              widget.file,
              userProfile: context.read<MediaCellBloc>().state.userProfile,
            ),
            icon: FlowySvgs.save_as_s,
            label: LocaleKeys.button_download.tr(),
          ),
        ],
        MediaMenuItem(
          onTap: () {
            widget.controller.close();
            showConfirmDeletionDialog(
              context: context,
              name: widget.file.name,
              description: LocaleKeys.grid_media_deleteFileDescription.tr(),
              onConfirm: () => widget.parentContext
                  .read<MediaCellBloc>()
                  .add(MediaCellEvent.removeFile(fileId: widget.file.id)),
            );
          },
          icon: FlowySvgs.trash_s,
          label: LocaleKeys.button_delete.tr(),
        ),
      ],
    );
  }

  void _saveName(BuildContext context) {
    final newName = widget.nameController.text.trim();
    if (newName.isEmpty) {
      return;
    }

    context
        .read<MediaCellBloc>()
        .add(MediaCellEvent.renameFile(fileId: widget.file.id, name: newName));
    Navigator.of(context).pop();
  }

  void _showRenameConfirmDialog() {
    showCustomConfirmDialog(
      context: widget.parentContext,
      title: LocaleKeys.document_plugins_file_renameFile_title.tr(),
      description: LocaleKeys.document_plugins_file_renameFile_description.tr(),
      closeOnConfirm: false,
      builder: (builderContext) => FileRenameTextField(
        nameController: widget.nameController,
        errorMessage: errorMessage,
        onSubmitted: () => _saveName(widget.parentContext),
        disposeController: false,
      ),
      style: ConfirmPopupStyle.cancelAndOk,
      confirmLabel: LocaleKeys.button_save.tr(),
      onConfirm: () => _saveName(widget.parentContext),
      onCancel: Navigator.of(widget.parentContext).pop,
    );
  }

  void _setCover(BuildContext context) => context.read<RowDetailBloc>().add(
        RowDetailEvent.setCover(
          RowCoverPB(
            data: widget.file.url,
            uploadType: widget.file.uploadType,
            coverType: CoverTypePB.FileCover,
          ),
        ),
      );

  void _showInteractiveViewer(BuildContext context) => showDialog(
        context: context,
        builder: (_) => InteractiveImageViewer(
          userProfile:
              widget.parentContext.read<MediaCellBloc>().state.userProfile,
          imageProvider: AFBlockImageProvider(
            initialIndex: widget.index,
            images: widget.images
                .map(
                  (e) => ImageBlockData(
                    url: e.url,
                    type: e.uploadType.toCustomImageType(),
                  ),
                )
                .toList(),
            onDeleteImage: (index) {
              final deleteFile = widget.images[index];
              widget.parentContext
                  .read<MediaCellBloc>()
                  .deleteFile(deleteFile.id);
            },
          ),
        ),
      );
}
