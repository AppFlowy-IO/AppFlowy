import 'dart:collection';
import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';

typedef FeatureFlagMap = Map<FeatureFlag, bool>;

/// The [FeatureFlag] is used to control the front-end features of the app.
///
/// For example, if your feature is still under development,
///   you can set the value to `false` to hide the feature.
enum FeatureFlag {
  // used to control the visibility of the collaborative workspace feature
  // if it's on, you can see the workspace list and the workspace settings
  // in the top-left corner of the app
  collaborativeWorkspace,

  // used to control the visibility of the members settings
  // if it's on, you can see the members settings in the settings page
  membersSettings;

  static Future<void> initialize() async {
    final values = await getIt<KeyValueStorage>().getWithFormat<FeatureFlagMap>(
          KVKeys.featureFlag,
          (value) => Map.from(jsonDecode(value)).map(
            (key, value) => MapEntry(
              FeatureFlag.values.firstWhere((e) => e.name == key),
              value as bool,
            ),
          ),
        ) ??
        {};

    _values = {
      ...{for (final flag in FeatureFlag.values) flag: false},
      ...values,
    };
  }

  static UnmodifiableMapView<FeatureFlag, bool> get data =>
      UnmodifiableMapView(_values);

  Future<void> turnOn() async {
    await update(true);
  }

  Future<void> turnOff() async {
    await update(false);
  }

  Future<void> update(bool value) async {
    _values[this] = value;

    await getIt<KeyValueStorage>().set(
      KVKeys.featureFlag,
      jsonEncode(
        _values.map((key, value) => MapEntry(key.name, value)),
      ),
    );
  }

  static Future<void> clear() async {
    _values = {};
    await getIt<KeyValueStorage>().remove(KVKeys.featureFlag);
  }

  bool get isOn {
    if (_values.containsKey(this)) {
      return _values[this]!;
    }

    switch (this) {
      case FeatureFlag.collaborativeWorkspace:
        return false;
      case FeatureFlag.membersSettings:
        return false;
    }
  }

  String get description {
    switch (this) {
      case FeatureFlag.collaborativeWorkspace:
        return 'if it\'s on, you can see the workspace list and the workspace settings in the top-left corner of the app';
      case FeatureFlag.membersSettings:
        return 'if it\'s on, you can see the members settings in the settings page';
    }
  }

  String get key => 'appflowy_feature_flag_${toString()}';
}

FeatureFlagMap _values = {};
