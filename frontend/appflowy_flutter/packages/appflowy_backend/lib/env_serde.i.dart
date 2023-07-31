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
      anon_key: json['anon_key'] as String,
      jwt_secret: json['jwt_secret'] as String,
    );

Map<String, dynamic> _$SupabaseConfigurationToJson(
        SupabaseConfiguration instance) =>
    <String, dynamic>{
      'enable_sync': instance.enable_sync,
      'url': instance.url,
      'anon_key': instance.anon_key,
      'jwt_secret': instance.jwt_secret,
    };
