import 'package:appflowy/features/mension_person/data/models/member.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'mention_repository.dart';

class MockMentionRepository extends MentionRepository {
  final List<Member> _mockMembers = [
    Member(
      id: '1',
      name: 'Andrew Christian',
      type: MemberType.member,
      email: 'andrewchristian@appflowy.io',
    ),
    Member(
      id: '2',
      name: 'Andrew Tate',
      type: MemberType.member,
      email: 'andrewtate@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/boy',
    ),
    Member(
      id: '3',
      name: 'Emma Johnson',
      type: MemberType.member,
      email: 'emmajohnson@appflowy.io',
      avatarUrl: 'https://avatar.iran.liara.run/public/girl',
    ),
    Member(
      id: '4',
      name: 'Michael Brown',
      type: MemberType.member,
      email: 'michaelbrown@appflowy.io',
    ),
  ];

  @override
  Future<FlowyResult<List<Member>, FlowyError>> getMembers({
    required String workspaceId,
  }) async {
    return FlowySuccess(_mockMembers);
  }
}
