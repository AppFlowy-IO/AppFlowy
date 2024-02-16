import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:dartz/dartz.dart';

class SearchBackendService {
  static Future<Either<RepeatedSearchResultPB, FlowyError>> performSearch(
    String keyword,
  ) async {
    final request = SearchQueryPB(search: keyword);

    return SearchEventSearch(request).send();
  }
}
