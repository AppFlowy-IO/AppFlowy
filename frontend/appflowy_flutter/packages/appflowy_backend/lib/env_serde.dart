import 'package:json_annotation/json_annotation.dart';

// Run `dart run build_runner build` to generate the json serialization If the
// file `env_serde.i.dart` is existed, delete it first.
//
// the file `env_serde.g.dart` will be generated in the same directory. Rename
// the file to `env_serde.i.dart` because the file is ignored by default.
part 'env_serde.i.dart';

@JsonSerializable()
class AppFlowyEnv {
  final SupabaseConfiguration supabase_config;

  AppFlowyEnv({
    required this.supabase_config,
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
  final String key;
  final String jwt_secret;
  final PostgresConfiguration postgres_config;

  SupabaseConfiguration({
    this.enable_sync = true,
    required this.url,
    required this.key,
    required this.jwt_secret,
    required this.postgres_config,
  });

  factory SupabaseConfiguration.fromJson(Map<String, dynamic> json) =>
      _$SupabaseConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$SupabaseConfigurationToJson(this);
}

@JsonSerializable()
class PostgresConfiguration {
  final String url;
  final String user_name;
  final String password;
  final int port;

  PostgresConfiguration({
    required this.url,
    required this.user_name,
    required this.password,
    required this.port,
  });

  factory PostgresConfiguration.fromJson(Map<String, dynamic> json) =>
      _$PostgresConfigurationFromJson(json);

  Map<String, dynamic> toJson() => _$PostgresConfigurationToJson(this);
}
