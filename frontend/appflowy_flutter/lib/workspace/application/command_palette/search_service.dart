import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/query.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/search_filter.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class SearchBackendService {
  static Future<FlowyResult<void, FlowyError>> performSearch(
    String keyword, [
    String? workspaceId,
  ]) async {
    final filter = SearchFilterPB(workspaceId: workspaceId);
    final request = SearchQueryPB(search: keyword, filter: filter);

    return SearchEventSearch(request).send();
  }
}
