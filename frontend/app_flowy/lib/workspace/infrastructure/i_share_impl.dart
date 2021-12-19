import 'package:app_flowy/workspace/domain/i_share.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/protobuf.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

import 'repos/share_repo.dart';

class IShareImpl extends IShare {
  ShareRepo repo;

  IShareImpl({required this.repo});

  @override
  Future<Either<ExportData, FlowyError>> exportText(String docId) {
    return repo.export(docId, ExportType.Text);
  }

  @override
  Future<Either<ExportData, FlowyError>> exportMarkdown(String docId) {
    return repo.export(docId, ExportType.Markdown);
  }

  @override
  Future<Either<ExportData, FlowyError>> exportURL(String docId) {
    return repo.export(docId, ExportType.Link);
  }
}
