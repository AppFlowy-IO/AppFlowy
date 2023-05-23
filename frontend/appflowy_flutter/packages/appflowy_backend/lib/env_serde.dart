import 'package:json_annotation/json_annotation.dart';

part 'env_serde.l.dart';

@JsonSerializable()
class AppFlowyEnv {
  final SupabaseConfiguration supabase_config;
  final SupabaseDBConfig supabase_db_config;

  AppFlowyEnv(
      {required this.supabase_config, required this.supabase_db_config});

  factory AppFlowyEnv.fromJson(Map<String, dynamic> json) =>
      _$AppFlowyEnvFromJson(json);

  Map<String, dynamic> toJson() => _$AppFlowyEnvToJson(this);
}

@JsonSerializable()
class SupabaseConfiguration {
  final String url;
  final String key;
  final String jwt_secret;

  SupabaseConfiguration(
      {required this.url, required this.key, required this.jwt_secret});

  factory SupabaseConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SupabaseConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SupabaseConfigurationToJson(this);
}

@JsonSerializable()
class SupabaseDBConfig {
  final String url;
  final String key;
  final String jwt_secret;
  final CollabTableConfig collab_table_config;

  SupabaseDBConfig(
      {required this.url,
      required this.key,
      required this.jwt_secret,
      required this.collab_table_config});

  factory SupabaseDBConfig.fromJson(Map<String, dynamic> json) =>
      _$SupabaseDBConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SupabaseDBConfigToJson(this);
}

@JsonSerializable()
class CollabTableConfig {
  final String table_name;
  final bool enable;

  CollabTableConfig({required this.table_name, required this.enable});

  factory CollabTableConfig.fromJson(Map<String, dynamic> json) =>
      _$CollabTableConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CollabTableConfigToJson(this);
}
