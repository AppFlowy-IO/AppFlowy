import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-date/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class DateService {
  static Future<Either<FlowyError, DateTime>> queryDate(String search) async {
    final query = DateQueryPB.create()..query = search;
    final result = (await DateEventQueryDate(query).send()).swap();
    return result.fold((l) => left(l), (r) {
      final date = DateTime.tryParse(r.date);
      if (date != null) {
        return right(date);
      }

      return left(FlowyError(msg: 'Could not parse Date (NLP) from String'));
    });
  }
}
