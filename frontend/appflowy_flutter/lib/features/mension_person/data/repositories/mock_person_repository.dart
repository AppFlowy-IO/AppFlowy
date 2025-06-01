import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy/features/mension_person/data/repositories/person_repository.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class MockPersonRepository extends PersonRepository {
  @override
  Future<FlowyResult<PersonWithAccess, FlowyError>> getPerson({
    required String documentId,
    required String personId,
  }) async {
    return FlowySuccess(
      PersonWithAccess(
        person: Person(
          id: personId,
          name: 'Andrew Christian',
          role: PersonRole.member,
          email: 'andrewchristian@appflowy.io',
          avatarUrl: 'https://avatar.iran.liara.run/public',
        ),
        access: true,
      ),
    );
  }
}
