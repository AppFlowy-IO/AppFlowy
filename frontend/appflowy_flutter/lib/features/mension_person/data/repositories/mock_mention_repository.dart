import 'package:appflowy/features/mension_person/data/models/person.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'mention_repository.dart';

class MockMentionRepository extends MentionRepository {
  final List<Person> _mockMembers = [
    Person(
      id: '1',
      name: 'Andrew Christian',
      role: PersonRole.member,
      email: 'andrewchristian@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public',
    ),
    Person(
      id: '2',
      name: 'Andrew Tate',
      role: PersonRole.member,
      email: 'andrewtate@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
    Person(
      id: '3',
      name: 'Emma Johnson',
      role: PersonRole.member,
      email: 'emmajohnson@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/girl',
    ),
    Person(
      id: '4',
      name: 'Michael Brown',
      role: PersonRole.member,
      email: 'michaelbrown@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/13',
    ),
    Person(
      id: '5',
      name: 'Nathan Brooks',
      role: PersonRole.member,
      email: 'nathanbrooks@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy/10',
    ),
  ];

  @override
  Future<FlowyResult<List<Person>, FlowyError>> getPersons({
    required String workspaceId,
  }) async {
    return FlowySuccess(_mockMembers);
  }
}
