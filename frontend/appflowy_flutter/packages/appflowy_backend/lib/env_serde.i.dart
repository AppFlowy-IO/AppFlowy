// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_serde.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppFlowyEnv _$AppFlowyEnvFromJson(Map<String, dynamic> json) => AppFlowyEnv(
      supabase_config: SupabaseConfiguration.fromJson(
          json['supabase_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppFlowyEnvToJson(AppFlowyEnv instance) =>
    <String, dynamic>{
      'supabase_config': instance.supabase_config,
    };

SupabaseConfiguration _$SupabaseConfigurationFromJson(
        Map<String, dynamic> json) =>
    SupabaseConfiguration(
      enable_sync: json['enable_sync'] as bool? ?? true,
      url: json['url'] as String,
      key: json['key'] as String,
      jwt_secret: json['jwt_secret'] as String,
      postgres_config: PostgresConfiguration.fromJson(
          json['postgres_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SupabaseConfigurationToJson(
        SupabaseConfiguration instance) =>
    <String, dynamic>{
      'enable_sync': instance.enable_sync,
      'url': instance.url,
      'key': instance.key,
      'jwt_secret': instance.jwt_secret,
      'postgres_config': instance.postgres_config,
    };

PostgresConfiguration _$PostgresConfigurationFromJson(
        Map<String, dynamic> json) =>
    PostgresConfiguration(
      url: json['url'] as String,
      user_name: json['user_name'] as String,
      password: json['password'] as String,
      port: json['port'] as int,
    );

Map<String, dynamic> _$PostgresConfigurationToJson(
        PostgresConfiguration instance) =>
    <String, dynamic>{
      'url': instance.url,
      'user_name': instance.user_name,
      'password': instance.password,
      'port': instance.port,
    };
