///
//  Generated code. Do not modify.
//  source: subject.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum ObservableSubject_OneOfSubjectPayload {
  subjectPayload, 
  notSet
}

class ObservableSubject extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ObservableSubject_OneOfSubjectPayload> _ObservableSubject_OneOfSubjectPayloadByTag = {
    4 : ObservableSubject_OneOfSubjectPayload.subjectPayload,
    0 : ObservableSubject_OneOfSubjectPayload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ObservableSubject', createEmptyInstance: create)
    ..oo(0, [4])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'category')
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ty', $pb.PbFieldType.O3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subjectId')
    ..a<$core.List<$core.int>>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'subjectPayload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  ObservableSubject._() : super();
  factory ObservableSubject({
    $core.String? category,
    $core.int? ty,
    $core.String? subjectId,
    $core.List<$core.int>? subjectPayload,
  }) {
    final _result = create();
    if (category != null) {
      _result.category = category;
    }
    if (ty != null) {
      _result.ty = ty;
    }
    if (subjectId != null) {
      _result.subjectId = subjectId;
    }
    if (subjectPayload != null) {
      _result.subjectPayload = subjectPayload;
    }
    return _result;
  }
  factory ObservableSubject.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ObservableSubject.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ObservableSubject clone() => ObservableSubject()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ObservableSubject copyWith(void Function(ObservableSubject) updates) => super.copyWith((message) => updates(message as ObservableSubject)) as ObservableSubject; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ObservableSubject create() => ObservableSubject._();
  ObservableSubject createEmptyInstance() => create();
  static $pb.PbList<ObservableSubject> createRepeated() => $pb.PbList<ObservableSubject>();
  @$core.pragma('dart2js:noInline')
  static ObservableSubject getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ObservableSubject>(create);
  static ObservableSubject? _defaultInstance;

  ObservableSubject_OneOfSubjectPayload whichOneOfSubjectPayload() => _ObservableSubject_OneOfSubjectPayloadByTag[$_whichOneof(0)]!;
  void clearOneOfSubjectPayload() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get category => $_getSZ(0);
  @$pb.TagNumber(1)
  set category($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCategory() => $_has(0);
  @$pb.TagNumber(1)
  void clearCategory() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get ty => $_getIZ(1);
  @$pb.TagNumber(2)
  set ty($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTy() => $_has(1);
  @$pb.TagNumber(2)
  void clearTy() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get subjectId => $_getSZ(2);
  @$pb.TagNumber(3)
  set subjectId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSubjectId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSubjectId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get subjectPayload => $_getN(3);
  @$pb.TagNumber(4)
  set subjectPayload($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSubjectPayload() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubjectPayload() => clearField(4);
}

