import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/entities.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class SearchBackendService {
  static Future<FlowyResult<void, FlowyError>> performSearch(
    String keyword,
  ) async {
    final request = SearchQueryPB(search: keyword);

    return SearchEventSearch(request).send();
  }
}
