import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-database/database_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

class DatabaseBackendService {
  static Future<Either<List<DatabaseDescriptionPB>, FlowyError>>
      getAllDatabases() {
    return DatabaseEventGetDatabases().send().then((final result) {
      return result.fold((final l) => left(l.items), (final r) => right(r));
    });
  }
}
