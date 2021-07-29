///
//  Generated code. Do not modify.
//  source: workspace_delete.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class DeleteWorkspaceRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DeleteWorkspaceRequest', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspaceId')
    ..hasRequiredFields = false
  ;

  DeleteWorkspaceRequest._() : super();
  factory DeleteWorkspaceRequest({
    $core.String? workspaceId,
  }) {
    final _result = create();
    if (workspaceId != null) {
      _result.workspaceId = workspaceId;
    }
    return _result;
  }
  factory DeleteWorkspaceRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteWorkspaceRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteWorkspaceRequest clone() => DeleteWorkspaceRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteWorkspaceRequest copyWith(void Function(DeleteWorkspaceRequest) updates) => super.copyWith((message) => updates(message as DeleteWorkspaceRequest)) as DeleteWorkspaceRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DeleteWorkspaceRequest create() => DeleteWorkspaceRequest._();
  DeleteWorkspaceRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteWorkspaceRequest> createRepeated() => $pb.PbList<DeleteWorkspaceRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteWorkspaceRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteWorkspaceRequest>(create);
  static DeleteWorkspaceRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get workspaceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set workspaceId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasWorkspaceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWorkspaceId() => clearField(1);
}

