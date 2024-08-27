import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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
      builder: (_, state) {
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
                      child: _RenderMedia(
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
                    onInsertLocalFile: (file) async {
                      if (file.path.isEmpty) return;

                      final fileType = file.mimeType?.startsWith('image/') ??
                              false || imgExtensionRegex.hasMatch(file.name)
                          ? MediaFileTypePB.Image
                          : MediaFileTypePB.Other;

                      final mediaCellBloc = context.read<MediaCellBloc>();

                      // Check upload type
                      final userProfile = mediaCellBloc.userProfile;
                      final isLocalMode =
                          userProfile.authenticator == AuthenticatorPB.Local;

                      String? path;
                      String? errorMsg;
                      if (isLocalMode) {
                        path = await saveFileToLocalStorage(file.path);
                      } else {
                        (path, errorMsg) = await saveFileToCloudStorage(
                          file.path,
                          mediaCellBloc.databaseId,
                        );
                      }

                      if (errorMsg != null) {
                        return showSnackBarMessage(context, errorMsg);
                      }

                      if (mediaCellBloc.isClosed || path == null) {
                        return;
                      }

                      mediaCellBloc.add(
                        MediaCellEvent.addFile(
                          url: path,
                          name: file.name,
                          uploadType: isLocalMode
                              ? MediaUploadTypePB.LocalMedia
                              : MediaUploadTypePB.CloudMedia,
                          fileType: fileType,
                        ),
                      );

                      addFilePopoverController.close();
                    },
                    onInsertNetworkFile: (url) {
                      if (url.isEmpty) return;

                      final uri = Uri.tryParse(url);
                      if (uri == null) {
                        return showSnackBarMessage(
                          context,
                          'Invalid URL - Please try again',
                        );
                      }

                      String name = uri.pathSegments.last;
                      if (name.isEmpty && uri.pathSegments.length > 1) {
                        name = uri.pathSegments[uri.pathSegments.length - 2];
                      }

                      context.read<MediaCellBloc>().add(
                            MediaCellEvent.addFile(
                              url: url,
                              name: name,
                              uploadType: MediaUploadTypePB.NetworkMedia,
                              fileType: MediaFileTypePB.Other,
                            ),
                          );

                      addFilePopoverController.close();
                    },
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: addFilePopoverController.show,
                    child: const FlowyHover(
                      resetHoverOnRebuild: false,
                      child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Row(
                          children: [
                            FlowySvg(FlowySvgs.add_s),
                            HSpace(8),
                            FlowyText('Add a file or image'),
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

class _RenderMedia extends StatefulWidget {
  const _RenderMedia({
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
  State<_RenderMedia> createState() => __RenderMediaState();
}

class __RenderMediaState extends State<_RenderMedia> {
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
                            context.read<MediaCellBloc>().userProfile,
                        height: 64,
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
                              height: 64,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            )
                          : Image.file(
                              File(widget.file.url),
                              height: 64,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
                            ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => afLaunchUrlString(widget.file.url),
                      child: FlowyText(
                        widget.file.name,
                        overflow: TextOverflow.ellipsis,
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
                    popupBuilder: (_) => BlocProvider.value(
                      value: context.read<MediaCellBloc>(),
                      child: _MediaItemMenu(file: widget.file),
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
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => InteractiveImageViewer(
            userProfile: context.read<MediaCellBloc>().userProfile,
            imageProvider: AFBlockImageProvider(
              images: [
                ImageBlockData(
                  url: file.url,
                  type: file.uploadType.toCustomImageType(),
                ),
              ],
              onDeleteImage: (_) => context
                  .read<MediaCellBloc>()
                  .add(MediaCellEvent.removeFile(fileId: file.id)),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class _MediaItemMenu extends StatelessWidget {
  const _MediaItemMenu({
    required this.file,
  });

  final MediaFilePB file;

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const VSpace(4),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (file.fileType == MediaFileTypePB.Image) ...[
          FlowyButton(
            onTap: () => showDialog(
              context: context,
              builder: (_) => InteractiveImageViewer(
                userProfile: context.read<MediaCellBloc>().userProfile,
                imageProvider: AFBlockImageProvider(
                  images: [
                    ImageBlockData(
                      url: file.url,
                      type: file.uploadType.toCustomImageType(),
                    ),
                  ],
                  onDeleteImage: (_) => context
                      .read<MediaCellBloc>()
                      .add(MediaCellEvent.removeFile(fileId: file.id)),
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
          onTap: () async {
            if ([MediaUploadTypePB.NetworkMedia, MediaUploadTypePB.LocalMedia]
                .contains(file.uploadType)) {
              /// When the file is a network file or a local file, we can directly open the file.
              await afLaunchUrl(Uri.parse(file.url));
            } else {
              final userProfile = context.read<MediaCellBloc>().userProfile;
              final uri = Uri.parse(file.url);
              final imgFile = File(uri.pathSegments.last);
              final savePath = await FilePicker().saveFile(
                fileName: basename(imgFile.path),
              );

              if (savePath != null) {
                final uri = Uri.parse(file.url);

                final token = jsonDecode(userProfile.token)['access_token'];
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
          },
          leftIcon: FlowySvg(
            FlowySvgs.download_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(18),
          ),
          text: FlowyText.regular(
            'Download',
            color: AFThemeExtension.of(context).textColor,
          ),
          leftIconSize: const Size(18, 18),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        FlowyButton(
          onTap: () => context.read<MediaCellBloc>().add(
                MediaCellEvent.removeFile(
                  fileId: file.id,
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
}
