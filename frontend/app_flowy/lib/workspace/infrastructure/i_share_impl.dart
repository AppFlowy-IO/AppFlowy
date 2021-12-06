import 'package:app_flowy/workspace/domain/i_share.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
import 'package:dartz/dartz.dart';

import 'repos/share_repo.dart';

class IShareImpl extends IShare {
  ShareRepo repo;

  IShareImpl({required this.repo});

  @override
  Future<Either<ExportData, WorkspaceError>> exportText(String docId) {
    return repo.export(docId, ExportType.Text);
  }

  @override
  Future<Either<ExportData, WorkspaceError>> exportMarkdown(String docId) {
    return repo.export(docId, ExportType.Markdown);
  }

  @override
  Future<Either<ExportData, WorkspaceError>> exportURL(String docId) {
    return repo.export(docId, ExportType.Link);
  }
}
