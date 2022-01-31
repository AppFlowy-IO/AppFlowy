import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart' show UserProfile;

class NewUser {
  UserProfile profile;
  String workspaceId;
  NewUser({
    required this.profile,
    required this.workspaceId,
  });
}
