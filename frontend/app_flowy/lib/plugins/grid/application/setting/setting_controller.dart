import 'package:app_flowy/plugins/grid/application/setting/setting_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/setting_entities.pb.dart';
import 'setting_listener.dart';

typedef OnError = void Function(FlowyError);
typedef OnSettingUpdated = void Function(GridSettingPB);

class SettingController {
  final String viewId;
  final SettingFFIService _ffiService;
  final SettingListener _listener;
  OnSettingUpdated? _onSettingUpdated;
  OnError? _onError;
  GridSettingPB? _setting;
  GridSettingPB? get setting => _setting;

  SettingController({
    required this.viewId,
  })  : _ffiService = SettingFFIService(viewId: viewId),
        _listener = SettingListener(gridId: viewId) {
    // Load setting
    _ffiService.getSetting().then((result) {
      result.fold(
        (newSetting) => updateSetting(newSetting),
        (err) => _onError?.call(err),
      );
    });

    // Listen on the seting changes
    _listener.start(onSettingUpdated: (result) {
      result.fold(
        (newSetting) => updateSetting(newSetting),
        (err) => _onError?.call(err),
      );
    });
  }

  void startListeing({
    required OnSettingUpdated onSettingUpdated,
    required OnError onError,
  }) {
    assert(_onSettingUpdated == null, 'Should call once');
    assert(_onError == null, 'Should call once');
    _onSettingUpdated = onSettingUpdated;
    _onError = onError;
  }

  void updateSetting(GridSettingPB newSetting) {
    _setting = newSetting;
    _onSettingUpdated?.call(newSetting);
  }

  void dispose() {
    _onSettingUpdated = null;
    _onError = null;
    _listener.stop();
  }
}
