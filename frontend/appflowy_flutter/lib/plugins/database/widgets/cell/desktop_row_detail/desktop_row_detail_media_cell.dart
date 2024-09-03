import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/media.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/image_provider.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/file_picker/file_picker_impl.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

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
                            padding: const EdgeInsets.all(6),
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
        Positioned(top: 5, right: 5, child: FileItemMenu(file: widget.file)),
      ],
    );
  }
}

class FileItemMenu extends StatefulWidget {
  const FileItemMenu({super.key, required this.file});

  final MediaFilePB file;

  @override
  State<FileItemMenu> createState() => _FileItemMenuState();
}

class _FileItemMenuState extends State<FileItemMenu> {
  final popoverController = PopoverController();
  final nameController = TextEditingController();
  final errorMessage = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    nameController.text = widget.file.name;
  }

  @override
  void dispose() {
    popoverController.close();
    errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: const BoxConstraints(maxWidth: 150),
      direction: PopoverDirection.bottomWithRightAligned,
      offset: const Offset(0, 5),
      popupBuilder: (_) {
        return SeparatedColumn(
          separatorBuilder: () => const VSpace(4),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.file.fileType == MediaFileTypePB.Image) ...[
              FlowyButton(
                onTap: () {
                  popoverController.close();
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
                        onDeleteImage: (_) => context.read<MediaCellBloc>().add(
                              MediaCellEvent.removeFile(fileId: widget.file.id),
                            ),
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
              leftIcon: const FlowySvg(FlowySvgs.edit_s),
              text: FlowyText.regular(LocaleKeys.grid_media_rename.tr()),
              onTap: () {
                popoverController.close();

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
                  builder: (dialogContext) {
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
              onTap: () async {
                if ([
                  MediaUploadTypePB.NetworkMedia,
                  MediaUploadTypePB.LocalMedia,
                ].contains(widget.file.uploadType)) {
                  /// When the file is a network file or a local file, we can directly open the file.
                  await afLaunchUrl(Uri.parse(widget.file.url));
                } else {
                  final userProfile =
                      context.read<MediaCellBloc>().state.userProfile;
                  if (userProfile == null) return;

                  final uri = Uri.parse(widget.file.url);
                  final imgFile = File(uri.pathSegments.last);
                  final savePath = await FilePicker().saveFile(
                    fileName: basename(imgFile.path),
                  );

                  if (savePath != null) {
                    final uri = Uri.parse(widget.file.url);

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
                        LocaleKeys.document_plugins_image_imageDownloadFailed
                            .tr(),
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
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.all(Corners.s8Radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: FlowyIconButton(
            width: 20,
            radius: BorderRadius.circular(0),
            icon: FlowySvg(
              FlowySvgs.three_dots_s,
              color: AFThemeExtension.of(context).textColor,
            ),
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
