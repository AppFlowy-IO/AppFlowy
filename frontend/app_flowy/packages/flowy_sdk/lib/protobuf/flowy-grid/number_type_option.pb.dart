///
//  Generated code. Do not modify.
//  source: number_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'format.pbenum.dart' as $0;

class NumberTypeOptionPB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NumberTypeOptionPB', createEmptyInstance: create)
    ..e<$0.NumberFormat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'format', $pb.PbFieldType.OE, defaultOrMaker: $0.NumberFormat.Num, valueOf: $0.NumberFormat.valueOf, enumValues: $0.NumberFormat.values)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scale', $pb.PbFieldType.OU3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'symbol')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signPositive')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  NumberTypeOptionPB._() : super();
  factory NumberTypeOptionPB({
    $0.NumberFormat? format,
    $core.int? scale,
    $core.String? symbol,
    $core.bool? signPositive,
    $core.String? name,
  }) {
    final _result = create();
    if (format != null) {
      _result.format = format;
    }
    if (scale != null) {
      _result.scale = scale;
    }
    if (symbol != null) {
      _result.symbol = symbol;
    }
    if (signPositive != null) {
      _result.signPositive = signPositive;
    }
    if (name != null) {
      _result.name = name;
    }
    return _result;
  }
  factory NumberTypeOptionPB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NumberTypeOptionPB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NumberTypeOptionPB clone() => NumberTypeOptionPB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NumberTypeOptionPB copyWith(void Function(NumberTypeOptionPB) updates) => super.copyWith((message) => updates(message as NumberTypeOptionPB)) as NumberTypeOptionPB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NumberTypeOptionPB create() => NumberTypeOptionPB._();
  NumberTypeOptionPB createEmptyInstance() => create();
  static $pb.PbList<NumberTypeOptionPB> createRepeated() => $pb.PbList<NumberTypeOptionPB>();
  @$core.pragma('dart2js:noInline')
  static NumberTypeOptionPB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NumberTypeOptionPB>(create);
  static NumberTypeOptionPB? _defaultInstance;

  @$pb.TagNumber(1)
  $0.NumberFormat get format => $_getN(0);
  @$pb.TagNumber(1)
  set format($0.NumberFormat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get scale => $_getIZ(1);
  @$pb.TagNumber(2)
  set scale($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasScale() => $_has(1);
  @$pb.TagNumber(2)
  void clearScale() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get symbol => $_getSZ(2);
  @$pb.TagNumber(3)
  set symbol($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSymbol() => $_has(2);
  @$pb.TagNumber(3)
  void clearSymbol() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get signPositive => $_getBF(3);
  @$pb.TagNumber(4)
  set signPositive($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSignPositive() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignPositive() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get name => $_getSZ(4);
  @$pb.TagNumber(5)
  set name($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasName() => $_has(4);
  @$pb.TagNumber(5)
  void clearName() => clearField(5);
}

