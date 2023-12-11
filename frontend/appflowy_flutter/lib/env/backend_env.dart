// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
part 'backend_env.g.dart';

@JsonSerializable()
class AppFlowyConfiguration {
  final String root;
  final String custom_app_path;
  final String origin_app_path;
  final String device_id;
  final int authenticator_type;
  final SupabaseConfiguration supabase_config;
  final AppFlowyCloudConfiguration appflowy_cloud_config;
  final Map<String, String> envs;

  AppFlowyConfiguration({
    required this.root,
    required this.custom_app_path,
    required this.origin_app_path,
    required this.device_id,
    required this.authenticator_type,
    required this.supabase_config,
    required this.appflowy_cloud_config,
    required this.envs,
  });

  factory AppFlowyConfiguration.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$AppFlowyConfigurationToJson(this);
}

@JsonSerializable()
class SupabaseConfiguration {
  /// Indicates whether the sync feature is enabled.
  final String url;
  final String anon_key;

  SupabaseConfiguration({
    required this.url,
    required this.anon_key,
  });

  factory SupabaseConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SupabaseConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SupabaseConfigurationToJson(this);

  static SupabaseConfiguration defaultConfig() {
    return SupabaseConfiguration(
      url: '',
      anon_key: '',
    );
  }

  bool get isValid {
    return url.isNotEmpty && anon_key.isNotEmpty;
  }
}

@JsonSerializable()
class AppFlowyCloudConfiguration {
  final String base_url;
  final String ws_base_url;
  final String gotrue_url;

  AppFlowyCloudConfiguration({
    required this.base_url,
    required this.ws_base_url,
    required this.gotrue_url,
  });

  factory AppFlowyCloudConfiguration.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyCloudConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$AppFlowyCloudConfigurationToJson(this);

  static AppFlowyCloudConfiguration defaultConfig() {
    return AppFlowyCloudConfiguration(
      base_url: '',
      ws_base_url: '',
      gotrue_url: '',
    );
  }

  bool get isValid {
    return base_url.isNotEmpty &&
        ws_base_url.isNotEmpty &&
        gotrue_url.isNotEmpty;
  }
}
