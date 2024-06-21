import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';

extension PresentableUsage on WorkspaceUsagePB {
  String get totalBlobInGb =>
      (totalBlobBytesLimit.toInt() / 1024 / 1024 / 1024).round().toString();
  String get currentBlobInGb =>
      (totalBlobBytes.toInt() / 1024 / 1024 / 1024).round().toString();
}
