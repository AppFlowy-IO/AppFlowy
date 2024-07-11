import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:intl/intl.dart';

final _storageNumberFormat = NumberFormat()
  ..maximumFractionDigits = 2
  ..minimumFractionDigits = 0;

extension PresentableUsage on WorkspaceUsagePB {
  String get totalBlobInGb =>
      (storageBytesLimit.toInt() / 1024 / 1024 / 1024).round().toString();

  /// We use [NumberFormat] to format the current blob in GB.
  ///
  /// Where the [totalBlobBytes] is the total blob bytes in bytes.
  /// And [NumberFormat.maximumFractionDigits] is set to 2.
  /// And [NumberFormat.minimumFractionDigits] is set to 0.
  ///
  String get currentBlobInGb =>
      _storageNumberFormat.format(storageBytes.toInt() / 1024 / 1024 / 1024);
}
