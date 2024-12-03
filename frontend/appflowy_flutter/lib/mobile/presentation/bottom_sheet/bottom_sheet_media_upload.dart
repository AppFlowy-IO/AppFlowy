import 'package:appflowy/plugins/database/application/cell/bloc/media_cell_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_util.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/mobile_file_upload_menu.dart';
import 'package:appflowy/util/xfile_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/media_entities.pbenum.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MobileMediaUploadSheetContent extends StatelessWidget {
  const MobileMediaUploadSheetContent({super.key, required this.dialogContext});

  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      constraints: const BoxConstraints(
        maxHeight: 340,
        minHeight: 80,
      ),
      child: MobileFileUploadMenu(
        onInsertLocalFile: (files) async {
          dialogContext.pop();

          await insertLocalFiles(
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
            },
          );
        },
        onInsertNetworkFile: (url) async => _onInsertNetworkFile(
          url,
          dialogContext,
          context,
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
