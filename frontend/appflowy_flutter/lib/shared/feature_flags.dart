import 'dart:convert';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:collection/collection.dart';

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
  membersSettings,

  // used to control the sync feature of the document
  // if it's on, the document will be synced the events from server in real-time
  syncDocument,

  // used to control the sync feature of the database
  // if it's on, the collaborators will show in the database
  syncDatabase,

  // used for the search feature
  search,

  // used for ignore the conflicted feature flag
  unknown;

  static Future<void> initialize() async {
    final values = await getIt<KeyValueStorage>().getWithFormat<FeatureFlagMap>(
          KVKeys.featureFlag,
          (value) => Map.from(jsonDecode(value)).map(
            (key, value) {
              final k = FeatureFlag.values.firstWhereOrNull(
                    (e) => e.name == key,
                  ) ??
                  FeatureFlag.unknown;
              return MapEntry(k, value as bool);
            },
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
    if ([
      // release this feature in version 0.5.6
      FeatureFlag.collaborativeWorkspace,
      FeatureFlag.membersSettings,
      // release this feature in version 0.5.4
      FeatureFlag.syncDatabase,
      FeatureFlag.syncDocument,
    ].contains(this)) {
      return true;
    }

    if (_values.containsKey(this)) {
      return _values[this]!;
    }

    switch (this) {
      case FeatureFlag.collaborativeWorkspace:
      case FeatureFlag.membersSettings:
      case FeatureFlag.search:
      case FeatureFlag.unknown:
        return false;
      case FeatureFlag.syncDocument:
      case FeatureFlag.syncDatabase:
        return true;
    }
  }

  String get description {
    switch (this) {
      case FeatureFlag.collaborativeWorkspace:
        return 'if it\'s on, you can see the workspace list and the workspace settings in the top-left corner of the app';
      case FeatureFlag.membersSettings:
        return 'if it\'s on, you can see the members settings in the settings page';
      case FeatureFlag.syncDocument:
        return 'if it\'s on, the document will be synced in real-time';
      case FeatureFlag.syncDatabase:
        return 'if it\'s on, the collaborators will show in the database';
      case FeatureFlag.search:
        return 'if it\'s on, the command palette and search button will be available';
      case FeatureFlag.unknown:
        return '';
    }
  }

  String get key => 'appflowy_feature_flag_${toString()}';
}

FeatureFlagMap _values = {};
