import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

abstract class PersonRepository {
  /// Gets the list of persons
  Future<FlowyResult<PersonWithAccess, FlowyError>> getPerson({
    required String documentId,
    required String personId,
  });
}

