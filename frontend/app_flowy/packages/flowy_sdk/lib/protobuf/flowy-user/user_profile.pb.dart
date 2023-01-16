///
//  Generated code. Do not modify.
//  source: user_profile.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UserTokenPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserTokenPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..hasRequiredFields = false
  ;

  UserTokenPB._() : super();
  factory UserTokenPB({
    $core.String? token,
  }) {
    final _result = create();
    if (token != null) {
      _result.token = token;
    }
    return _result;
  }
  factory UserTokenPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserTokenPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserTokenPB clone() => UserTokenPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserTokenPB copyWith(void Function(UserTokenPB) updates) => super.copyWith((message) => updates(message as UserTokenPB)) as UserTokenPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserTokenPB create() => UserTokenPB._();
  UserTokenPB createEmptyInstance() => create();
  static $pb.PbList<UserTokenPB> createRepeated() => $pb.PbList<UserTokenPB>();
  @$core.pragma('dart2js:noInline')
  static UserTokenPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserTokenPB>(create);
  static UserTokenPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => clearField(1);
}

class UserSettingPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserSettingPB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'userFolder')
    ..hasRequiredFields = false
  ;

  UserSettingPB._() : super();
  factory UserSettingPB({
    $core.String? userFolder,
  }) {
    final _result = create();
    if (userFolder != null) {
      _result.userFolder = userFolder;
    }
    return _result;
  }
  factory UserSettingPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserSettingPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserSettingPB clone() => UserSettingPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserSettingPB copyWith(void Function(UserSettingPB) updates) => super.copyWith((message) => updates(message as UserSettingPB)) as UserSettingPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserSettingPB create() => UserSettingPB._();
  UserSettingPB createEmptyInstance() => create();
  static $pb.PbList<UserSettingPB> createRepeated() => $pb.PbList<UserSettingPB>();
  @$core.pragma('dart2js:noInline')
  static UserSettingPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserSettingPB>(create);
  static UserSettingPB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get userFolder => $_getSZ(0);
  @$pb.TagNumber(1)
  set userFolder($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserFolder() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserFolder() => clearField(1);
}

class UserProfilePB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UserProfilePB', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'token')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'iconUrl')
    ..hasRequiredFields = false
  ;

  UserProfilePB._() : super();
  factory UserProfilePB({
    $core.String? id,
    $core.String? email,
    $core.String? name,
    $core.String? token,
    $core.String? iconUrl,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (email != null) {
      _result.email = email;
    }
    if (name != null) {
      _result.name = name;
    }
    if (token != null) {
      _result.token = token;
    }
    if (iconUrl != null) {
      _result.iconUrl = iconUrl;
    }
    return _result;
  }
  factory UserProfilePB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UserProfilePB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UserProfilePB clone() => UserProfilePB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UserProfilePB copyWith(void Function(UserProfilePB) updates) => super.copyWith((message) => updates(message as UserProfilePB)) as UserProfilePB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UserProfilePB create() => UserProfilePB._();
  UserProfilePB createEmptyInstance() => create();
  static $pb.PbList<UserProfilePB> createRepeated() => $pb.PbList<UserProfilePB>();
  @$core.pragma('dart2js:noInline')
  static UserProfilePB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UserProfilePB>(create);
  static UserProfilePB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get email => $_getSZ(1);
  @$pb.TagNumber(2)
  set email($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEmail() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmail() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get token => $_getSZ(3);
  @$pb.TagNumber(4)
  set token($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearToken() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get iconUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set iconUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIconUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearIconUrl() => clearField(5);
}

enum UpdateUserProfilePayloadPB_OneOfName {
  name, 
  notSet
}

enum UpdateUserProfilePayloadPB_OneOfEmail {
  email, 
  notSet
}

enum UpdateUserProfilePayloadPB_OneOfPassword {
  password, 
  notSet
}

enum UpdateUserProfilePayloadPB_OneOfIconUrl {
  iconUrl, 
  notSet
}

class UpdateUserProfilePayloadPB extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateUserProfilePayloadPB_OneOfName> _UpdateUserProfilePayloadPB_OneOfNameByTag = {
    2 : UpdateUserProfilePayloadPB_OneOfName.name,
    0 : UpdateUserProfilePayloadPB_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfilePayloadPB_OneOfEmail> _UpdateUserProfilePayloadPB_OneOfEmailByTag = {
    3 : UpdateUserProfilePayloadPB_OneOfEmail.email,
    0 : UpdateUserProfilePayloadPB_OneOfEmail.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfilePayloadPB_OneOfPassword> _UpdateUserProfilePayloadPB_OneOfPasswordByTag = {
    4 : UpdateUserProfilePayloadPB_OneOfPassword.password,
    0 : UpdateUserProfilePayloadPB_OneOfPassword.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfilePayloadPB_OneOfIconUrl> _UpdateUserProfilePayloadPB_OneOfIconUrlByTag = {
    5 : UpdateUserProfilePayloadPB_OneOfIconUrl.iconUrl,
    0 : UpdateUserProfilePayloadPB_OneOfIconUrl.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateUserProfilePayloadPB', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'iconUrl')
    ..hasRequiredFields = false
  ;

  UpdateUserProfilePayloadPB._() : super();
  factory UpdateUserProfilePayloadPB({
    $core.String? id,
    $core.String? name,
    $core.String? email,
    $core.String? password,
    $core.String? iconUrl,
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
    if (password != null) {
      _result.password = password;
    }
    if (iconUrl != null) {
      _result.iconUrl = iconUrl;
    }
    return _result;
  }
  factory UpdateUserProfilePayloadPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateUserProfilePayloadPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateUserProfilePayloadPB clone() => UpdateUserProfilePayloadPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateUserProfilePayloadPB copyWith(void Function(UpdateUserProfilePayloadPB) updates) => super.copyWith((message) => updates(message as UpdateUserProfilePayloadPB)) as UpdateUserProfilePayloadPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateUserProfilePayloadPB create() => UpdateUserProfilePayloadPB._();
  UpdateUserProfilePayloadPB createEmptyInstance() => create();
  static $pb.PbList<UpdateUserProfilePayloadPB> createRepeated() => $pb.PbList<UpdateUserProfilePayloadPB>();
  @$core.pragma('dart2js:noInline')
  static UpdateUserProfilePayloadPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateUserProfilePayloadPB>(create);
  static UpdateUserProfilePayloadPB? _defaultInstance;

  UpdateUserProfilePayloadPB_OneOfName whichOneOfName() => _UpdateUserProfilePayloadPB_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateUserProfilePayloadPB_OneOfEmail whichOneOfEmail() => _UpdateUserProfilePayloadPB_OneOfEmailByTag[$_whichOneof(1)]!;
  void clearOneOfEmail() => clearField($_whichOneof(1));

  UpdateUserProfilePayloadPB_OneOfPassword whichOneOfPassword() => _UpdateUserProfilePayloadPB_OneOfPasswordByTag[$_whichOneof(2)]!;
  void clearOneOfPassword() => clearField($_whichOneof(2));

  UpdateUserProfilePayloadPB_OneOfIconUrl whichOneOfIconUrl() => _UpdateUserProfilePayloadPB_OneOfIconUrlByTag[$_whichOneof(3)]!;
  void clearOneOfIconUrl() => clearField($_whichOneof(3));

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
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get iconUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set iconUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIconUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearIconUrl() => clearField(5);
}

enum UpdateUserProfileParams_OneOfName {
  name, 
  notSet
}

enum UpdateUserProfileParams_OneOfEmail {
  email, 
  notSet
}

enum UpdateUserProfileParams_OneOfPassword {
  password, 
  notSet
}

enum UpdateUserProfileParams_OneOfIconUrl {
  iconUrl, 
  notSet
}

class UpdateUserProfileParams extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, UpdateUserProfileParams_OneOfName> _UpdateUserProfileParams_OneOfNameByTag = {
    2 : UpdateUserProfileParams_OneOfName.name,
    0 : UpdateUserProfileParams_OneOfName.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfileParams_OneOfEmail> _UpdateUserProfileParams_OneOfEmailByTag = {
    3 : UpdateUserProfileParams_OneOfEmail.email,
    0 : UpdateUserProfileParams_OneOfEmail.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfileParams_OneOfPassword> _UpdateUserProfileParams_OneOfPasswordByTag = {
    4 : UpdateUserProfileParams_OneOfPassword.password,
    0 : UpdateUserProfileParams_OneOfPassword.notSet
  };
  static const $core.Map<$core.int, UpdateUserProfileParams_OneOfIconUrl> _UpdateUserProfileParams_OneOfIconUrlByTag = {
    5 : UpdateUserProfileParams_OneOfIconUrl.iconUrl,
    0 : UpdateUserProfileParams_OneOfIconUrl.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'UpdateUserProfileParams', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'email')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'password')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'iconUrl')
    ..hasRequiredFields = false
  ;

  UpdateUserProfileParams._() : super();
  factory UpdateUserProfileParams({
    $core.String? id,
    $core.String? name,
    $core.String? email,
    $core.String? password,
    $core.String? iconUrl,
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
    if (password != null) {
      _result.password = password;
    }
    if (iconUrl != null) {
      _result.iconUrl = iconUrl;
    }
    return _result;
  }
  factory UpdateUserProfileParams.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateUserProfileParams.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateUserProfileParams clone() => UpdateUserProfileParams()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateUserProfileParams copyWith(void Function(UpdateUserProfileParams) updates) => super.copyWith((message) => updates(message as UpdateUserProfileParams)) as UpdateUserProfileParams; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static UpdateUserProfileParams create() => UpdateUserProfileParams._();
  UpdateUserProfileParams createEmptyInstance() => create();
  static $pb.PbList<UpdateUserProfileParams> createRepeated() => $pb.PbList<UpdateUserProfileParams>();
  @$core.pragma('dart2js:noInline')
  static UpdateUserProfileParams getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateUserProfileParams>(create);
  static UpdateUserProfileParams? _defaultInstance;

  UpdateUserProfileParams_OneOfName whichOneOfName() => _UpdateUserProfileParams_OneOfNameByTag[$_whichOneof(0)]!;
  void clearOneOfName() => clearField($_whichOneof(0));

  UpdateUserProfileParams_OneOfEmail whichOneOfEmail() => _UpdateUserProfileParams_OneOfEmailByTag[$_whichOneof(1)]!;
  void clearOneOfEmail() => clearField($_whichOneof(1));

  UpdateUserProfileParams_OneOfPassword whichOneOfPassword() => _UpdateUserProfileParams_OneOfPasswordByTag[$_whichOneof(2)]!;
  void clearOneOfPassword() => clearField($_whichOneof(2));

  UpdateUserProfileParams_OneOfIconUrl whichOneOfIconUrl() => _UpdateUserProfileParams_OneOfIconUrlByTag[$_whichOneof(3)]!;
  void clearOneOfIconUrl() => clearField($_whichOneof(3));

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
  $core.String get password => $_getSZ(3);
  @$pb.TagNumber(4)
  set password($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPassword() => $_has(3);
  @$pb.TagNumber(4)
  void clearPassword() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get iconUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set iconUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIconUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearIconUrl() => clearField(5);
}

