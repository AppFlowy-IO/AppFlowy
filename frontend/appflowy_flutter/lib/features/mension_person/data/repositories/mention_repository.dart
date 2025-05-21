

import 'package:appflowy/features/mension_person/data/models/member.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

abstract class MentionRepository {
  /// Gets the list of persons
  Future<FlowyResult<List<Member>, FlowyError>> getMembers({
    required String workspaceId,
  });
}
