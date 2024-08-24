// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
part 'backend_env.g.dart';

@JsonSerializable()
class AppFlowyConfiguration {
  AppFlowyConfiguration({
    required this.root,
    required this.app_version,
    required this.custom_app_path,
    required this.origin_app_path,
    required this.device_id,
    required this.platform,
    required this.authenticator_type,
    required this.appflowy_cloud_config,
    required this.envs,
  });

  factory AppFlowyConfiguration.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyConfigurationFromJson(json);

  final String root;
  final String app_version;
  final String custom_app_path;
  final String origin_app_path;
  final String device_id;
  final String platform;
  final int authenticator_type;
  final AppFlowyCloudConfiguration appflowy_cloud_config;
  final Map<String, String> envs;

  Map<String, dynamic> toJson() => _$AppFlowyConfigurationToJson(this);
}

@JsonSerializable()
class AppFlowyCloudConfiguration {
  AppFlowyCloudConfiguration({
    required this.base_url,
    required this.ws_base_url,
    required this.gotrue_url,
  });

  factory AppFlowyCloudConfiguration.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyCloudConfigurationFromJson(json);

  final String base_url;
  final String ws_base_url;
  final String gotrue_url;

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
