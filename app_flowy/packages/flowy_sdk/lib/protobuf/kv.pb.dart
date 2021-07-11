///
//  Generated code. Do not modify.
//  source: kv.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

enum KeyValue_OneOfStrValue {
  strValue, 
  notSet
}

enum KeyValue_OneOfIntValue {
  intValue, 
  notSet
}

enum KeyValue_OneOfFloatValue {
  floatValue, 
  notSet
}

enum KeyValue_OneOfBoolValue {
  boolValue, 
  notSet
}

class KeyValue extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, KeyValue_OneOfStrValue> _KeyValue_OneOfStrValueByTag = {
    2 : KeyValue_OneOfStrValue.strValue,
    0 : KeyValue_OneOfStrValue.notSet
  };
  static const $core.Map<$core.int, KeyValue_OneOfIntValue> _KeyValue_OneOfIntValueByTag = {
    3 : KeyValue_OneOfIntValue.intValue,
    0 : KeyValue_OneOfIntValue.notSet
  };
  static const $core.Map<$core.int, KeyValue_OneOfFloatValue> _KeyValue_OneOfFloatValueByTag = {
    4 : KeyValue_OneOfFloatValue.floatValue,
    0 : KeyValue_OneOfFloatValue.notSet
  };
  static const $core.Map<$core.int, KeyValue_OneOfBoolValue> _KeyValue_OneOfBoolValueByTag = {
    5 : KeyValue_OneOfBoolValue.boolValue,
    0 : KeyValue_OneOfBoolValue.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'KeyValue', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..oo(3, [5])
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'strValue')
    ..aInt64(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'intValue')
    ..a<$core.double>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'floatValue', $pb.PbFieldType.OD)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'boolValue')
    ..hasRequiredFields = false
  ;

  KeyValue._() : super();
  factory KeyValue({
    $core.String? key,
    $core.String? strValue,
    $fixnum.Int64? intValue,
    $core.double? floatValue,
    $core.bool? boolValue,
  }) {
    final _result = create();
    if (key != null) {
      _result.key = key;
    }
    if (strValue != null) {
      _result.strValue = strValue;
    }
    if (intValue != null) {
      _result.intValue = intValue;
    }
    if (floatValue != null) {
      _result.floatValue = floatValue;
    }
    if (boolValue != null) {
      _result.boolValue = boolValue;
    }
    return _result;
  }
  factory KeyValue.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory KeyValue.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  KeyValue clone() => KeyValue()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  KeyValue copyWith(void Function(KeyValue) updates) => super.copyWith((message) => updates(message as KeyValue)) as KeyValue; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static KeyValue create() => KeyValue._();
  KeyValue createEmptyInstance() => create();
  static $pb.PbList<KeyValue> createRepeated() => $pb.PbList<KeyValue>();
  @$core.pragma('dart2js:noInline')
  static KeyValue getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KeyValue>(create);
  static KeyValue? _defaultInstance;

  KeyValue_OneOfStrValue whichOneOfStrValue() => _KeyValue_OneOfStrValueByTag[$_whichOneof(0)]!;
  void clearOneOfStrValue() => clearField($_whichOneof(0));

  KeyValue_OneOfIntValue whichOneOfIntValue() => _KeyValue_OneOfIntValueByTag[$_whichOneof(1)]!;
  void clearOneOfIntValue() => clearField($_whichOneof(1));

  KeyValue_OneOfFloatValue whichOneOfFloatValue() => _KeyValue_OneOfFloatValueByTag[$_whichOneof(2)]!;
  void clearOneOfFloatValue() => clearField($_whichOneof(2));

  KeyValue_OneOfBoolValue whichOneOfBoolValue() => _KeyValue_OneOfBoolValueByTag[$_whichOneof(3)]!;
  void clearOneOfBoolValue() => clearField($_whichOneof(3));

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get strValue => $_getSZ(1);
  @$pb.TagNumber(2)
  set strValue($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStrValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearStrValue() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get intValue => $_getI64(2);
  @$pb.TagNumber(3)
  set intValue($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIntValue() => $_has(2);
  @$pb.TagNumber(3)
  void clearIntValue() => clearField(3);

  @$pb.TagNumber(4)
  $core.double get floatValue => $_getN(3);
  @$pb.TagNumber(4)
  set floatValue($core.double v) { $_setDouble(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFloatValue() => $_has(3);
  @$pb.TagNumber(4)
  void clearFloatValue() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get boolValue => $_getBF(4);
  @$pb.TagNumber(5)
  set boolValue($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasBoolValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearBoolValue() => clearField(5);
}

