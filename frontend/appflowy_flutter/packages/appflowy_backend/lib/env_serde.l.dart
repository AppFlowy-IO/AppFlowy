// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env_serde.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppFlowyEnv _$AppFlowyEnvFromJson(Map<String, dynamic> json) => AppFlowyEnv(
      supabase_config: SupabaseConfiguration.fromJson(
          json['supabase_config'] as Map<String, dynamic>),
      supabase_db_config: SupabaseDBConfig.fromJson(
          json['supabase_db_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppFlowyEnvToJson(AppFlowyEnv instance) =>
    <String, dynamic>{
      'supabase_config': instance.supabase_config,
      'supabase_db_config': instance.supabase_db_config,
    };

SupabaseConfiguration _$SupabaseConfigurationFromJson(
        Map<String, dynamic> json) =>
    SupabaseConfiguration(
      url: json['url'] as String,
      key: json['key'] as String,
      jwt_secret: json['jwt_secret'] as String,
    );

Map<String, dynamic> _$SupabaseConfigurationToJson(
        SupabaseConfiguration instance) =>
    <String, dynamic>{
      'url': instance.url,
      'key': instance.key,
      'jwt_secret': instance.jwt_secret,
    };

SupabaseDBConfig _$SupabaseDBConfigFromJson(Map<String, dynamic> json) =>
    SupabaseDBConfig(
      url: json['url'] as String,
      key: json['key'] as String,
      jwt_secret: json['jwt_secret'] as String,
      collab_table_config: CollabTableConfig.fromJson(
          json['collab_table_config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SupabaseDBConfigToJson(SupabaseDBConfig instance) =>
    <String, dynamic>{
      'url': instance.url,
      'key': instance.key,
      'jwt_secret': instance.jwt_secret,
      'collab_table_config': instance.collab_table_config,
    };

CollabTableConfig _$CollabTableConfigFromJson(Map<String, dynamic> json) =>
    CollabTableConfig(
      table_name: json['table_name'] as String,
      enable: json['enable'] as bool,
    );

Map<String, dynamic> _$CollabTableConfigToJson(CollabTableConfig instance) =>
    <String, dynamic>{
      'table_name': instance.table_name,
      'enable': instance.enable,
    };
