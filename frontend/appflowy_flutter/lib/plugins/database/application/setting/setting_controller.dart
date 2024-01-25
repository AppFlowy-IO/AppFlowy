import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pb.dart';
import 'setting_listener.dart';
import 'setting_service.dart';

typedef OnError = void Function(FlowyError);
typedef OnSettingUpdated = void Function(DatabaseViewSettingPB);

class SettingController {
  SettingController({
    required this.viewId,
  })  : _settingBackendSvc = SettingBackendService(viewId: viewId),
        _listener = DatabaseSettingListener(viewId: viewId) {
    // Load setting
    _settingBackendSvc.getSetting().then((result) {
      result.fold(
        (newSetting) => updateSetting(newSetting),
        (err) => _onError?.call(err),
      );
    });

    // Listen on the setting changes
    _listener.start(
      onSettingUpdated: (result) {
        result.fold(
          (newSetting) => updateSetting(newSetting),
          (err) => _onError?.call(err),
        );
      },
    );
  }

  final String viewId;
  final SettingBackendService _settingBackendSvc;
  final DatabaseSettingListener _listener;

  OnSettingUpdated? _onSettingUpdated;
  OnError? _onError;
  DatabaseViewSettingPB? _setting;
  DatabaseViewSettingPB? get setting => _setting;

  void startListening({
    required OnSettingUpdated onSettingUpdated,
    required OnError onError,
  }) {
    assert(_onSettingUpdated == null, 'Should call once');
    assert(_onError == null, 'Should call once');
    _onSettingUpdated = onSettingUpdated;
    _onError = onError;
  }

  void updateSetting(DatabaseViewSettingPB newSetting) {
    _setting = newSetting;
    _onSettingUpdated?.call(newSetting);
  }

  void dispose() {
    _onSettingUpdated = null;
    _onError = null;
    _listener.stop();
  }
}
