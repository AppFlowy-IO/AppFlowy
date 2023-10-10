import 'package:json_annotation/json_annotation.dart';

// Run `dart run build_runner build` to generate the json serialization If the
// file `env_serde.g.dart` is existed, delete it first.
//
// the file `env_serde.g.dart` will be generated in the same directory.
part 'env_serde.g.dart';

@JsonSerializable()
class AppFlowyEnv {
  final SupabaseConfiguration supabase_config;
  final AppFlowyCloudConfiguration appflowy_cloud_config;

  AppFlowyEnv({
    required this.supabase_config,
    required this.appflowy_cloud_config,
  });

  factory AppFlowyEnv.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyEnvFromJson(json);

  Map<String, dynamic> toJson() => _$AppFlowyEnvToJson(this);
}

@JsonSerializable()
class SupabaseConfiguration {
  /// Indicates whether the sync feature is enabled.
  final bool enable_sync;
  final String url;
  final String anon_key;

  SupabaseConfiguration({
    this.enable_sync = true,
    required this.url,
    required this.anon_key,
  });

  factory SupabaseConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SupabaseConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SupabaseConfigurationToJson(this);
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
}
