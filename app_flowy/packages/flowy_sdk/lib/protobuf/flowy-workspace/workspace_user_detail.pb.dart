///
//  Generated code. Do not modify.
//  source: workspace_user_detail.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CurrentWorkspace extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CurrentWorkspace', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'owner')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..hasRequiredFields = false
  ;

  CurrentWorkspace._() : super();
  factory CurrentWorkspace({
    $core.String? owner,
    $core.String? workspaceId,
  }) {
    final _result = create();
    if (owner != null) {
      _result.owner = owner;
    }
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    return _result;
  }
  factory CurrentWorkspace.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CurrentWorkspace.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CurrentWorkspace clone() => CurrentWorkspace()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CurrentWorkspace copyWith(void Function(CurrentWorkspace) updates) => super.copyWith((message) => updates(message as CurrentWorkspace)) as CurrentWorkspace; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspace create() => CurrentWorkspace._();
  CurrentWorkspace createEmptyInstance() => create();
  static $pb.PbList<CurrentWorkspace> createRepeated() => $pb.PbList<CurrentWorkspace>();
  @$core.pragma('dart2js:noInline')
  static CurrentWorkspace getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CurrentWorkspace>(create);
  static CurrentWorkspace? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get owner => $_getSZ(0);
  @$pb.TagNumber(1)
  set owner($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasOwner() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwner() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get workspaceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set workspaceId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasWorkspaceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearWorkspaceId() => clearField(2);
}

