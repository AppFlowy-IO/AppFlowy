import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MediaCellEditor extends StatefulWidget {
  const MediaCellEditor({super.key});

  @override
  State<MediaCellEditor> createState() => _MediaCellEditorState();
}

class _MediaCellEditorState extends State<MediaCellEditor> {
  final addFilePopoverController = PopoverController();
  final itemMutex = PopoverMutex();

  @override
  void dispose() {
    addFilePopoverController.close();
    itemMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaCellBloc, MediaCellState>(
      builder: (context, state) {
        final images = state.files
            .where((file) => file.fileType == MediaFileTypePB.Image)
            .toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.files.isNotEmpty) ...[
              Flexible(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.all(6),
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemBuilder: (_, index) => BlocProvider.value(
                    key: Key(state.files[index].id),
                    value: context.read<MediaCellBloc>(),
                    child: RenderMedia(
                      file: state.files[index],
                      images: images,
                      index: index,
                      enableReordering: state.files.length > 1,
                      mutex: itemMutex,
                    ),
                  ),
                  itemCount: state.files.length,
                  onReorder: (from, to) {
                    if (from < to) {
                      to--;
                    }

                    context
                        .read<MediaCellBloc>()
                        .add(MediaCellEvent.reorderFiles(from: from, to: to));
                  },
                  proxyDecorator: (child, index, animation) => Material(
                    color: Colors.transparent,
                    child: SizeTransition(
                      sizeFactor: animation,
                      child: child,
                    ),
                  ),
                ),
              ),
            ],
            _AddButton(addFilePopoverController: addFilePopoverController),
          ],
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.addFilePopoverController});

  final PopoverController addFilePopoverController;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: addFilePopoverController,
      direction: PopoverDirection.bottomWithCenterAligned,
      offset: const Offset(0, 10),
      constraints: const BoxConstraints(maxWidth: 350),
      triggerActions: PopoverTriggerFlags.none,
      popupBuilder: (popoverContext) => FileUploadMenu(
        allowMultipleFiles: true,
        onInsertLocalFile: (files) async => insertLocalFiles(
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

            addFilePopoverController.close();
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

          addFilePopoverController.close();
        },
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: addFilePopoverController.show,
            child: FlowyHover(
              resetHoverOnRebuild: false,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    FlowySvg(
                      FlowySvgs.add_thin_s,
                      size: const Size.square(14),
                      color: AFThemeExtension.of(context).lightIconColor,
                    ),
                    const HSpace(8),
                    FlowyText.regular(
                      LocaleKeys.grid_media_addFileOrImage.tr(),
                      figmaLineHeight: 20,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension ToCustomImageType on FileUploadTypePB {
  CustomImageType toCustomImageType() => switch (this) {
        FileUploadTypePB.NetworkFile => CustomImageType.external,
        FileUploadTypePB.CloudFile => CustomImageType.internal,
        _ => CustomImageType.local,
      };
}

@visibleForTesting
class RenderMedia extends StatefulWidget {
  const RenderMedia({
    super.key,
    required this.index,
    required this.file,
    required this.images,
    required this.enableReordering,
    required this.mutex,
  });

  final int index;
  final MediaFilePB file;
  final List<MediaFilePB> images;
  final bool enableReordering;
  final PopoverMutex mutex;

  @override
  State<RenderMedia> createState() => _RenderMediaState();
}

class _RenderMediaState extends State<RenderMedia> {
  bool isHovering = false;
  int? imageIndex;

  MediaFilePB get file => widget.file;

  late final controller = PopoverController();

  @override
  void initState() {
    super.initState();
    imageIndex = widget.images.indexOf(file);
  }

  @override
  void didUpdateWidget(covariant RenderMedia oldWidget) {
    imageIndex = widget.images.indexOf(file);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovering = true),
        onExit: (_) => setState(() => isHovering = false),
        cursor: SystemMouseCursors.click,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isHovering
                ? AFThemeExtension.of(context).greyHover
                : Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: widget.file.fileType == MediaFileTypePB.Image
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                enabled: widget.enableReordering,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FlowySvg(
                    FlowySvgs.drag_element_s,
                    color: AFThemeExtension.of(context).lightIconColor,
                  ),
                ),
              ),
              const HSpace(4),
              if (widget.file.fileType == MediaFileTypePB.Image) ...[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: _openInteractiveViewer(
                      context,
                      files: widget.images,
                      index: imageIndex!,
                      child: AFImage(
                        url: widget.file.url,
                        uploadType: widget.file.uploadType,
                        userProfile:
                            context.read<MediaCellBloc>().state.userProfile,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => afLaunchUrlString(file.url),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: FlowySvg(
                            file.fileType.icon,
                            color: AFThemeExtension.of(context).strongText,
                            size: const Size.square(12),
                          ),
                        ),
                        const HSpace(8),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: FlowyText(
                              file.name,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const HSpace(4),
              AppFlowyPopover(
                controller: controller,
                mutex: widget.mutex,
                asBarrier: true,
                offset: const Offset(0, 4),
                constraints: const BoxConstraints(maxWidth: 240),
                direction: PopoverDirection.bottomWithLeftAligned,
                popupBuilder: (popoverContext) => BlocProvider.value(
                  value: context.read<MediaCellBloc>(),
                  child: MediaItemMenu(
                    file: file,
                    images: widget.images,
                    index: imageIndex ?? -1,
                    closeContext: popoverContext,
                    onAction: () => controller.close(),
                  ),
                ),
                child: FlowyIconButton(
                  hoverColor: Colors.transparent,
                  width: 24,
                  icon: FlowySvg(
                    FlowySvgs.three_dots_s,
                    size: const Size.square(16),
                    color: AFThemeExtension.of(context).lightIconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _openInteractiveViewer(
    BuildContext context, {
    required List<MediaFilePB> files,
    required int index,
    required Widget child,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => openInteractiveViewerFromFiles(
          context,
          files,
          onDeleteImage: (index) {
            final deleteFile = files[index];
            context.read<MediaCellBloc>().deleteFile(deleteFile.id);
          },
          userProfile: context.read<MediaCellBloc>().state.userProfile,
          initialIndex: index,
        ),
        child: child,
      );
}

class MediaItemMenu extends StatefulWidget {
  const MediaItemMenu({
    super.key,
    required this.file,
    required this.images,
    required this.index,
    this.closeContext,
    this.onAction,
  });

  /// The [MediaFilePB] this menu concerns
  final MediaFilePB file;

  /// The list of [MediaFilePB] which are images
  /// This is used to show the [InteractiveImageViewer]
  final List<MediaFilePB> images;

  /// The index of the [MediaFilePB] in the [images] list
  final int index;

  /// The [BuildContext] used to show the [InteractiveImageViewer]
  final BuildContext? closeContext;

  /// Callback to be called when an action is performed
  final VoidCallback? onAction;

  @override
  State<MediaItemMenu> createState() => _MediaItemMenuState();
}

class _MediaItemMenuState extends State<MediaItemMenu> {
  late final nameController = TextEditingController(text: widget.file.name);
  final errorMessage = ValueNotifier<String?>(null);

  BuildContext? renameContext;

  @override
  void dispose() {
    nameController.dispose();
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
              widget.onAction?.call();
              _showInteractiveViewer();
            },
            icon: FlowySvgs.full_view_s,
            label: LocaleKeys.grid_media_expand.tr(),
          ),
          MediaMenuItem(
            onTap: () {
              context.read<MediaCellBloc>().add(
                    MediaCellEvent.setCover(
                      RowCoverPB(
                        data: widget.file.url,
                        uploadType: widget.file.uploadType,
                        coverType: CoverTypePB.FileCover,
                      ),
                    ),
                  );
              widget.onAction?.call();
            },
            icon: FlowySvgs.cover_s,
            label: LocaleKeys.grid_media_setAsCover.tr(),
          ),
        ],
        MediaMenuItem(
          onTap: () {
            widget.onAction?.call();
            afLaunchUrlString(widget.file.url);
          },
          icon: FlowySvgs.open_in_browser_s,
          label: LocaleKeys.grid_media_openInBrowser.tr(),
        ),
        MediaMenuItem(
          onTap: () async {
            await _showRenameDialog();
            widget.onAction?.call();
          },
          icon: FlowySvgs.rename_s,
          label: LocaleKeys.grid_media_rename.tr(),
        ),
        if (widget.file.uploadType == FileUploadTypePB.CloudFile) ...[
          MediaMenuItem(
            onTap: () async {
              await downloadMediaFile(
                context,
                widget.file,
                userProfile: context.read<MediaCellBloc>().state.userProfile,
              );
              widget.onAction?.call();
            },
            icon: FlowySvgs.save_as_s,
            label: LocaleKeys.button_download.tr(),
          ),
        ],
        MediaMenuItem(
          onTap: () async {
            await showConfirmDeletionDialog(
              context: context,
              name: widget.file.name,
              description: LocaleKeys.grid_media_deleteFileDescription.tr(),
              onConfirm: () => context
                  .read<MediaCellBloc>()
                  .add(MediaCellEvent.removeFile(fileId: widget.file.id)),
            );
            widget.onAction?.call();
          },
          icon: FlowySvgs.trash_s,
          label: LocaleKeys.button_delete.tr(),
        ),
      ],
    );
  }

  Future<void> _showRenameDialog() async {
    nameController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: nameController.text.length,
    );

    await showCustomConfirmDialog(
      context: context,
      title: LocaleKeys.document_plugins_file_renameFile_title.tr(),
      description: LocaleKeys.document_plugins_file_renameFile_description.tr(),
      closeOnConfirm: false,
      builder: (dialogContext) {
        renameContext = dialogContext;
        return FileRenameTextField(
          nameController: nameController,
          errorMessage: errorMessage,
          onSubmitted: () => _saveName(context),
          disposeController: false,
        );
      },
      confirmLabel: LocaleKeys.button_save.tr(),
      onConfirm: () => _saveName(context),
    );
  }

  void _saveName(BuildContext context) {
    if (nameController.text.isEmpty) {
      errorMessage.value =
          LocaleKeys.document_plugins_file_renameFile_nameEmptyError.tr();
      return;
    }

    context.read<MediaCellBloc>().add(
          MediaCellEvent.renameFile(
            fileId: widget.file.id,
            name: nameController.text,
          ),
        );

    if (renameContext != null) {
      Navigator.of(renameContext!).pop();
    }
  }

  void _showInteractiveViewer() {
    showDialog(
      context: widget.closeContext ?? context,
      builder: (_) => InteractiveImageViewer(
        userProfile: context.read<MediaCellBloc>().state.userProfile,
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
            context.read<MediaCellBloc>().deleteFile(deleteFile.id);
          },
        ),
      ),
    );
  }
}

class MediaMenuItem extends StatelessWidget {
  const MediaMenuItem({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final VoidCallback onTap;
  final FlowySvgData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      onTap: onTap,
      leftIcon: FlowySvg(icon),
      text: Padding(
        padding: const EdgeInsets.only(left: 4, top: 1, bottom: 1),
        child: FlowyText.regular(
          label,
          figmaLineHeight: 20,
        ),
      ),
      hoverColor: AFThemeExtension.of(context).lightGreyHover,
    );
  }
}
