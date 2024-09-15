import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/media_file_type_ext.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_upload_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/image_render.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pb.dart';
import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../document/presentation/editor_plugins/openai/widgets/loading.dart';

class MobileMediaCellEditor extends StatelessWidget {
  const MobileMediaCellEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(height: 420),
      child: BlocProvider.value(
        value: context.read<MediaCellBloc>(),
        child: BlocBuilder<MediaCellBloc, MediaCellState>(
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(),
              SizedBox(
                height: 44.0,
                child: Align(
                  child: FlowyText.medium(
                    LocaleKeys.grid_field_mediaFieldName.tr(),
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(height: 0.5),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: FlowyButton(
                          margin: const EdgeInsets.all(12),
                          onTap: () => showMobileBottomSheet(
                            context,
                            title: LocaleKeys.grid_media_addFileMobile.tr(),
                            showHeader: true,
                            showCloseButton: true,
                            showDragHandle: true,
                            builder: (dialogContext) => Container(
                              margin: const EdgeInsets.only(top: 12),
                              constraints: const BoxConstraints(
                                maxHeight: 340,
                                minHeight: 80,
                              ),
                              child: FileUploadMenu(
                                onInsertLocalFile: (files) async {
                                  dialogContext.pop();

                                  await insertLocalFiles(
                                    context,
                                    files,
                                    userProfile: context
                                        .read<MediaCellBloc>()
                                        .state
                                        .userProfile,
                                    documentId:
                                        context.read<MediaCellBloc>().rowId,
                                    onUploadSuccess: (file, path, isLocalMode) {
                                      final mediaCellBloc =
                                          context.read<MediaCellBloc>();
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
                                          fileType:
                                              file.fileType.toMediaFileTypePB(),
                                        ),
                                      );
                                    },
                                  );
                                },
                                onInsertNetworkFile: (url) async =>
                                    _onInsertNetworkFile(
                                  url,
                                  dialogContext,
                                  context,
                                ),
                              ),
                            ),
                          ),
                          text: const Row(
                            children: [
                              FlowySvg(
                                FlowySvgs.add_s,
                                size: Size.square(20),
                              ),
                              HSpace(8),
                              FlowyText('Add a file or image', fontSize: 15),
                            ],
                          ),
                        ),
                      ),
                      if (state.files.isNotEmpty) const Divider(height: .5),
                      ...state.files.map(
                        (file) => _FileItem(key: Key(file.id), file: file),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onInsertNetworkFile(
    String url,
    BuildContext dialogContext,
    BuildContext context,
  ) async {
    dialogContext.pop();

    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final fakeFile = XFile(uri.path);
    MediaFileTypePB fileType = fakeFile.fileType.toMediaFileTypePB();
    fileType =
        fileType == MediaFileTypePB.Other ? MediaFileTypePB.Link : fileType;

    String name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "";
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
  }
}

class _FileItem extends StatelessWidget {
  const _FileItem({super.key, required this.file});

  final MediaFilePB file;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Row(
            children: [
              if (file.fileType != MediaFileTypePB.Image) ...[
                FlowySvg(file.fileType.icon, size: const Size.square(24)),
                const HSpace(12),
                Expanded(
                  child: FlowyText(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    constraints: const BoxConstraints(maxHeight: 125),
                    child: GestureDetector(
                      onTap: () => openInteractiveViewer(context),
                      child: ImageRender(
                        userProfile:
                            context.read<MediaCellBloc>().state.userProfile,
                        fit: BoxFit.fitHeight,
                        image: ImageBlockData(
                          url: file.url,
                          type: file.uploadType.toCustomImageType(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              FlowyIconButton(
                width: 40,
                icon: const FlowySvg(
                  FlowySvgs.three_dots_s,
                  size: Size.square(20),
                ),
                onPressed: () => showMobileBottomSheet(
                  context,
                  showDragHandle: true,
                  builder: (_) => BlocProvider.value(
                    value: context.read<MediaCellBloc>(),
                    child: _EditFileSheet(file: file),
                  ),
                ),
              ),
              const HSpace(6),
            ],
          ),
        ),
        const Divider(height: .5),
      ],
    );
  }

  void openInteractiveViewer(BuildContext context) =>
      openInteractiveViewerFromFile(
        context,
        file,
        onDeleteImage: (_) => context.read<MediaCellBloc>().deleteFile(file.id),
        userProfile: context.read<MediaCellBloc>().state.userProfile,
      );
}

class _EditFileSheet extends StatefulWidget {
  const _EditFileSheet({required this.file});

  final MediaFilePB file;

  @override
  State<_EditFileSheet> createState() => __EditFileSheetState();
}

class __EditFileSheetState extends State<_EditFileSheet> {
  late final controller = TextEditingController(text: widget.file.name);
  Loading? loader;

  MediaFilePB get file => widget.file;

  @override
  void dispose() {
    controller.dispose();
    loader?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const VSpace(16),
          _FileTextField(
            file: file,
            controller: controller,
            onChanged: (name) =>
                context.read<MediaCellBloc>().renameFile(file.id, name),
          ),
          const VSpace(20),
          if (file.fileType == MediaFileTypePB.Image)
            FlowyOptionTile.text(
              text: LocaleKeys.grid_media_open.tr(),
              leftIcon: const FlowySvg(
                FlowySvgs.full_view_s,
                size: Size.square(20),
              ),
              onTap: () => openInteractiveViewer(context),
            ),
          FlowyOptionTile.text(
            text: file.fileType == MediaFileTypePB.Link
                ? LocaleKeys.grid_media_open.tr()
                : LocaleKeys.grid_media_download.tr(),
            leftIcon: FlowySvg(
              file.fileType == MediaFileTypePB.Link
                  ? FlowySvgs.m_link_m
                  : FlowySvgs.import_s,
              size: const Size.square(20),
            ),
            onTap: () async => downloadMediaFile(
              context,
              widget.file,
              userProfile: context.read<MediaCellBloc>().state.userProfile,
              onDownloadBegin: () {
                loader?.stop();
                loader = Loading(context);
                loader?.start();
              },
              onDownloadEnd: () => loader?.stop(),
            ),
          ),
          FlowyOptionTile.text(
            text: LocaleKeys.grid_media_delete.tr(),
            textColor: Theme.of(context).colorScheme.error,
            leftIcon: FlowySvg(
              FlowySvgs.trash_s,
              size: const Size.square(20),
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () {
              context.pop();
              context.read<MediaCellBloc>().deleteFile(file.id);
            },
          ),
        ],
      ),
    );
  }

  void openInteractiveViewer(BuildContext context) =>
      openInteractiveViewerFromFile(
        context,
        file,
        onDeleteImage: (_) => context.read<MediaCellBloc>().deleteFile(file.id),
        userProfile: context.read<MediaCellBloc>().state.userProfile,
      );
}

class _FileTextField extends StatelessWidget {
  const _FileTextField({
    required this.file,
    required this.controller,
    required this.onChanged,
  });

  final MediaFilePB file;
  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.textField(
      controller: controller,
      textFieldPadding: const EdgeInsets.symmetric(horizontal: 12),
      onTextChanged: onChanged,
      leftIcon: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: file.fileType.color,
        ),
        child: Center(
          child: FlowySvg(
            file.fileType.icon,
            size: const Size.square(22),
          ),
        ),
      ),
    );
  }
}
