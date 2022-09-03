import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/grid_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/setting_entities.pb.dart';

class SettingFFIService {
  final String viewId;

  const SettingFFIService({required this.viewId});

  Future<Either<GridSettingPB, FlowyError>> getSetting() {
    final payload = GridIdPB.create()..value = viewId;
    return GridEventGetGridSetting(payload).send();
  }
}
