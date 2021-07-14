///
//  Generated code. Do not modify.
//  source: user_update.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum UpdateUserRequest_OneOfName {
  name, 
  notSet
}

enum UpdateUserRequest_OneOfEmail {
  email, 
  notSet
}

enum UpdateUserRequest_OneOfWorkspace {
  workspace, 
  notSet
}

enum UpdateUserRequest_OneOfPassword {
  password, 
  notSet
}

class UpdateUserRequest extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateUserRequest_OneOfName> _UpdateUserRequest_OneOfNameByTag = {
    2 : UpdateUserRequest_OneOfName.name,
    0 : UpdateUserRequest_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateUserRequest_OneOfEmail> _UpdateUserRequest_OneOfEmailByTag = {
    3 : UpdateUserRequest_OneOfEmail.email,
    0 : UpdateUserRequest_OneOfEmail.notSet
  };
  static const $core.Map<$core.int, UpdateUserRequest_OneOfWorkspace> _UpdateUserRequest_OneOfWorkspaceByTag = {
    4 : UpdateUserRequest_OneOfWorkspace.workspace,
    0 : UpdateUserRequest_OneOfWorkspace.notSet
  };
  static const $core.Map<$core.int, UpdateUserRequest_OneOfPassword> _UpdateUserRequest_OneOfPasswordByTag = {
    5 : UpdateUserRequest_OneOfPassword.password,
    0 : UpdateUserRequest_OneOfPassword.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateUserRequest', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'workspace')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..hasRequiredFields = false
  ;

  UpdateUserRequest._() : super();
  factory UpdateUserRequest({
    $core.String? id,
    $core.String? name,
    $core.String? email,
    $core.String? workspace,
    $core.String? password,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (email != null) {
      _result.email = email;
    }
    if (workspace != null) {
      _result.workspace = workspace;
    }
    if (password != null) {
      _result.password = password;
    }
    return _result;
  }
  factory UpdateUserRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateUserRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateUserRequest clone() => UpdateUserRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateUserRequest copyWith(void Function(UpdateUserRequest) updates) => super.copyWith((message) => updates(message as UpdateUserRequest)) as UpdateUserRequest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateUserRequest create() => UpdateUserRequest._();
  UpdateUserRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateUserRequest> createRepeated() => $pb.PbList<UpdateUserRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateUserRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateUserRequest>(create);
  static UpdateUserRequest? _defaultInstance;

  UpdateUserRequest_OneOfName whichOneOfName() => _UpdateUserRequest_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateUserRequest_OneOfEmail whichOneOfEmail() => _UpdateUserRequest_OneOfEmailByTag[$_whichOneof(1)]!;
  void clearOneOfEmail() => clearField($_whichOneof(1));

  UpdateUserRequest_OneOfWorkspace whichOneOfWorkspace() => _UpdateUserRequest_OneOfWorkspaceByTag[$_whichOneof(2)]!;
  void clearOneOfWorkspace() => clearField($_whichOneof(2));

  UpdateUserRequest_OneOfPassword whichOneOfPassword() => _UpdateUserRequest_OneOfPasswordByTag[$_whichOneof(3)]!;
  void clearOneOfPassword() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get workspace => $_getSZ(3);
  @$pb.TagNumber(4)
  set workspace($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasWorkspace() => $_has(3);
  @$pb.TagNumber(4)
  void clearWorkspace() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get password => $_getSZ(4);
  @$pb.TagNumber(5)
  set password($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPassword() => $_has(4);
  @$pb.TagNumber(5)
  void clearPassword() => clearField(5);
}

