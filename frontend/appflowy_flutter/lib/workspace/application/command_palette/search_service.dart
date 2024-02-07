import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:dartz/dartz.dart';

class SearchBackendService {
  static Future<Either<RepeatedSearchDataPB, FlowyError>> performSearch(
    String keyword,
  ) async {
    final request = SearchRequestPB(search: keyword);

    return FolderEventSearch(request).send();
  }
}
