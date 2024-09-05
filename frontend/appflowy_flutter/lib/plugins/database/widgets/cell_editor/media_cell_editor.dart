import 'dart:io';

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
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
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
        return Padding(
          padding: const EdgeInsets.all(4),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.files.isNotEmpty) ...[
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemBuilder: (_, index) => BlocProvider.value(
                      key: Key(state.files[index].id),
                      value: context.read<MediaCellBloc>(),
                      child: RenderMedia(
                        file: state.files[index],
                        index: index,
                        enableReordering: state.files.length > 1,
                        mutex: itemMutex,
                      ),
                    ),
                    itemCount: state.files.length,
                    onReorder: (from, to) => context
                        .read<MediaCellBloc>()
                        .add(MediaCellEvent.reorderFiles(from: from, to: to)),
                    proxyDecorator: (child, index, animation) => Material(
                      color: Colors.transparent,
                      child: SizeTransition(
                        sizeFactor: animation,
                        child: child,
                      ),
                    ),
                  ),
                  const Divider(height: 8),
                ],
                AppFlowyPopover(
                  controller: addFilePopoverController,
                  direction: PopoverDirection.bottomWithCenterAligned,
                  offset: const Offset(0, 10),
                  constraints: const BoxConstraints(
                    minWidth: 250,
                    maxWidth: 250,
                  ),
                  triggerActions: PopoverTriggerFlags.none,
                  popupBuilder: (popoverContext) => FileUploadMenu(
                    onInsertLocalFile: (file) async => insertLocalFile(
                      context,
                      file,
                      userProfile:
                          context.read<MediaCellBloc>().state.userProfile,
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
                                ? MediaUploadTypePB.LocalMedia
                                : MediaUploadTypePB.CloudMedia,
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
                      MediaFileTypePB fileType =
                          fakeFile.fileType.toMediaFileTypePB();
                      fileType = fileType == MediaFileTypePB.Other
                          ? MediaFileTypePB.Link
                          : fileType;

                      String name = uri.pathSegments.isNotEmpty
                          ? uri.pathSegments.last
                          : "";
                      if (name.isEmpty && uri.pathSegments.length > 1) {
                        name = uri.pathSegments[uri.pathSegments.length - 2];
                      } else if (name.isEmpty) {
                        name = uri.host;
                      }

                      context.read<MediaCellBloc>().add(
                            MediaCellEvent.addFile(
                              url: url,
                              name: name,
                              uploadType: MediaUploadTypePB.NetworkMedia,
                              fileType: fileType,
                            ),
                          );

                      addFilePopoverController.close();
                    },
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: addFilePopoverController.show,
                    child: FlowyHover(
                      resetHoverOnRebuild: false,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            const FlowySvg(
                              FlowySvgs.add_s,
                              size: Size.square(18),
                            ),
                            const HSpace(8),
                            FlowyText(
                              LocaleKeys.grid_media_addFileOrImage.tr(),
                              lineHeight: 1.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension ToCustomImageType on MediaUploadTypePB {
  CustomImageType toCustomImageType() => switch (this) {
        MediaUploadTypePB.NetworkMedia => CustomImageType.external,
        MediaUploadTypePB.CloudMedia => CustomImageType.internal,
        _ => CustomImageType.local,
      };
}

@visibleForTesting
class RenderMedia extends StatefulWidget {
  const RenderMedia({
    super.key,
    required this.index,
    required this.file,
    required this.enableReordering,
    required this.mutex,
  });

  final int index;
  final MediaFilePB file;
  final bool enableReordering;
  final PopoverMutex mutex;

  @override
  State<RenderMedia> createState() => _RenderMediaState();
}

class _RenderMediaState extends State<RenderMedia> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isHovering
                ? AFThemeExtension.of(context).greyHover
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  enabled: widget.enableReordering,
                  child: const FlowySvg(FlowySvgs.drag_element_s),
                ),
                const HSpace(8),
                if (widget.file.fileType == MediaFileTypePB.Image &&
                    widget.file.uploadType == MediaUploadTypePB.CloudMedia) ...[
                  Expanded(
                    child: _openInteractiveViewer(
                      context,
                      file: widget.file,
                      child: FlowyNetworkImage(
                        url: widget.file.url,
                        userProfilePB:
                            context.read<MediaCellBloc>().state.userProfile,
                      ),
                    ),
                  ),
                ] else if (widget.file.fileType == MediaFileTypePB.Image) ...[
                  Expanded(
                    child: _openInteractiveViewer(
                      context,
                      file: widget.file,
                      child: widget.file.uploadType ==
                              MediaUploadTypePB.NetworkMedia
                          ? Image.network(
                              widget.file.url,
                              fit: BoxFit.cover,
                              alignment: Alignment.centerLeft,
                            )
                          : Image.file(
                              File(widget.file.url),
                              fit: BoxFit.cover,
                              alignment: Alignment.centerLeft,
                            ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => afLaunchUrlString(widget.file.url),
                      child: Row(
                        children: [
                          FlowySvg(
                            widget.file.fileType.icon,
                            color: AFThemeExtension.of(context).strongText,
                            size: const Size.square(18),
                          ),
                          const HSpace(8),
                          Flexible(
                            child: FlowyText(
                              widget.file.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AppFlowyPopover(
                    mutex: widget.mutex,
                    asBarrier: true,
                    constraints: const BoxConstraints(maxWidth: 150),
                    direction: PopoverDirection.bottomWithRightAligned,
                    popupBuilder: (popoverContext) => BlocProvider.value(
                      value: context.read<MediaCellBloc>(),
                      child: MediaItemMenu(
                        file: widget.file,
                        closeContext: popoverContext,
                      ),
                    ),
                    child: FlowyIconButton(
                      width: 24,
                      icon: FlowySvg(
                        FlowySvgs.three_dots_s,
                        color: AFThemeExtension.of(context).textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _openInteractiveViewer(
    BuildContext context, {
    required MediaFilePB file,
    required Widget child,
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => openInteractiveViewerFromFile(
          context,
          file,
          onDeleteImage: (_) =>
              context.read<MediaCellBloc>().deleteFile(file.id),
          userProfile: context.read<MediaCellBloc>().state.userProfile,
        ),
        child: child,
      );
}

class MediaItemMenu extends StatefulWidget {
  const MediaItemMenu({
    super.key,
    required this.file,
    this.closeContext,
  });

  final MediaFilePB file;
  final BuildContext? closeContext;

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
      separatorBuilder: () => const VSpace(4),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.file.fileType == MediaFileTypePB.Image) ...[
          FlowyButton(
            onTap: () => showDialog(
              context: widget.closeContext ?? context,
              builder: (_) => InteractiveImageViewer(
                userProfile: context.read<MediaCellBloc>().state.userProfile,
                imageProvider: AFBlockImageProvider(
                  images: [
                    ImageBlockData(
                      url: widget.file.url,
                      type: widget.file.uploadType.toCustomImageType(),
                    ),
                  ],
                  onDeleteImage: (_) =>
                      context.read<MediaCellBloc>().deleteFile(widget.file.id),
                ),
              ),
            ),
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
            size: const Size.square(18),
          ),
          leftIconSize: const Size(18, 18),
          text: FlowyText.regular(
            LocaleKeys.grid_media_rename.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          onTap: () {
            nameController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: nameController.text.length,
            );

            showCustomConfirmDialog(
              context: context,
              title: LocaleKeys.document_plugins_file_renameFile_title.tr(),
              description:
                  LocaleKeys.document_plugins_file_renameFile_description.tr(),
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
          onTap: () => context.read<MediaCellBloc>().add(
                MediaCellEvent.removeFile(
                  fileId: widget.file.id,
                ),
              ),
          leftIcon: FlowySvg(
            FlowySvgs.delete_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(18),
          ),
          text: FlowyText.regular(
            LocaleKeys.button_delete.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIconSize: const Size(18, 18),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
        ),
      ],
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
}
