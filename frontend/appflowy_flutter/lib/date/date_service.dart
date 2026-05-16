import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-date/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class DateService {
  static Future<FlowyResult<DateTime, FlowyError>> queryDate(
    String search,
  ) async {
    final query = DateQueryPB.create()..query = search;
    final result = await DateEventQueryDate(query).send();
    return result.fold(
      (s) {
        final date = DateTime.tryParse(s.date);
        if (date != null) {
          return FlowyResult.success(date);
        }
        return FlowyResult.failure(
          FlowyError(msg: 'Could not parse Date (NLP) from String'),
        );
      },
      (e) => FlowyResult.failure(e),
    );
  }
}
