// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
part 'backend_env.g.dart';

@JsonSerializable()
class AppFlowyConfiguration {
  final String custom_app_path;
  final String origin_app_path;
  final String device_id;
  final int cloud_type;
  final SupabaseConfiguration supabase_config;
  final AppFlowyCloudConfiguration appflowy_cloud_config;

  AppFlowyConfiguration({
    required this.custom_app_path,
    required this.origin_app_path,
    required this.device_id,
    required this.cloud_type,
    required this.supabase_config,
    required this.appflowy_cloud_config,
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
}
