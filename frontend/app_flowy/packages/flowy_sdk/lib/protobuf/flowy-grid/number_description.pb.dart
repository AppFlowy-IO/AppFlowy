///
//  Generated code. Do not modify.
//  source: number_description.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'number_description.pbenum.dart';

export 'number_description.pbenum.dart';

class NumberDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NumberDescription', createEmptyInstance: create)
    ..e<MoneySymbol>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'money', $pb.PbFieldType.OE, defaultOrMaker: MoneySymbol.CNY, valueOf: MoneySymbol.valueOf, enumValues: MoneySymbol.values)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scale', $pb.PbFieldType.OU3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'symbol')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signPositive')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  NumberDescription._() : super();
  factory NumberDescription({
    MoneySymbol? money,
    $core.int? scale,
    $core.String? symbol,
    $core.bool? signPositive,
    $core.String? name,
  }) {
    final _result = create();
    if (money != null) {
      _result.money = money;
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
  factory NumberDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NumberDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NumberDescription clone() => NumberDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NumberDescription copyWith(void Function(NumberDescription) updates) => super.copyWith((message) => updates(message as NumberDescription)) as NumberDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static NumberDescription create() => NumberDescription._();
  NumberDescription createEmptyInstance() => create();
  static $pb.PbList<NumberDescription> createRepeated() => $pb.PbList<NumberDescription>();
  @$core.pragma('dart2js:noInline')
  static NumberDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NumberDescription>(create);
  static NumberDescription? _defaultInstance;

  @$pb.TagNumber(1)
  MoneySymbol get money => $_getN(0);
  @$pb.TagNumber(1)
  set money(MoneySymbol v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMoney() => $_has(0);
  @$pb.TagNumber(1)
  void clearMoney() => clearField(1);

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

