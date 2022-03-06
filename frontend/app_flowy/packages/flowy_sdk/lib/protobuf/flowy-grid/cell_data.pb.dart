///
//  Generated code. Do not modify.
//  source: cell_data.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cell_data.pbenum.dart';

export 'cell_data.pbenum.dart';

class RichTextDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'RichTextDescription', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'format')
    ..hasRequiredFields = false
  ;

  RichTextDescription._() : super();
  factory RichTextDescription({
    $core.String? format,
  }) {
    final _result = create();
    if (format != null) {
      _result.format = format;
    }
    return _result;
  }
  factory RichTextDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RichTextDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RichTextDescription clone() => RichTextDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RichTextDescription copyWith(void Function(RichTextDescription) updates) => super.copyWith((message) => updates(message as RichTextDescription)) as RichTextDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RichTextDescription create() => RichTextDescription._();
  RichTextDescription createEmptyInstance() => create();
  static $pb.PbList<RichTextDescription> createRepeated() => $pb.PbList<RichTextDescription>();
  @$core.pragma('dart2js:noInline')
  static RichTextDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RichTextDescription>(create);
  static RichTextDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get format => $_getSZ(0);
  @$pb.TagNumber(1)
  set format($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormat() => clearField(1);
}

class CheckboxDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CheckboxDescription', createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'isSelected')
    ..hasRequiredFields = false
  ;

  CheckboxDescription._() : super();
  factory CheckboxDescription({
    $core.bool? isSelected,
  }) {
    final _result = create();
    if (isSelected != null) {
      _result.isSelected = isSelected;
    }
    return _result;
  }
  factory CheckboxDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CheckboxDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CheckboxDescription clone() => CheckboxDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CheckboxDescription copyWith(void Function(CheckboxDescription) updates) => super.copyWith((message) => updates(message as CheckboxDescription)) as CheckboxDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CheckboxDescription create() => CheckboxDescription._();
  CheckboxDescription createEmptyInstance() => create();
  static $pb.PbList<CheckboxDescription> createRepeated() => $pb.PbList<CheckboxDescription>();
  @$core.pragma('dart2js:noInline')
  static CheckboxDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CheckboxDescription>(create);
  static CheckboxDescription? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isSelected => $_getBF(0);
  @$pb.TagNumber(1)
  set isSelected($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIsSelected() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsSelected() => clearField(1);
}

class DateDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'DateDescription', createEmptyInstance: create)
    ..e<DateFormat>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dateFormat', $pb.PbFieldType.OE, defaultOrMaker: DateFormat.Local, valueOf: DateFormat.valueOf, enumValues: DateFormat.values)
    ..e<TimeFormat>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeFormat', $pb.PbFieldType.OE, defaultOrMaker: TimeFormat.TwelveHour, valueOf: TimeFormat.valueOf, enumValues: TimeFormat.values)
    ..hasRequiredFields = false
  ;

  DateDescription._() : super();
  factory DateDescription({
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
  }) {
    final _result = create();
    if (dateFormat != null) {
      _result.dateFormat = dateFormat;
    }
    if (timeFormat != null) {
      _result.timeFormat = timeFormat;
    }
    return _result;
  }
  factory DateDescription.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DateDescription.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DateDescription clone() => DateDescription()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DateDescription copyWith(void Function(DateDescription) updates) => super.copyWith((message) => updates(message as DateDescription)) as DateDescription; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static DateDescription create() => DateDescription._();
  DateDescription createEmptyInstance() => create();
  static $pb.PbList<DateDescription> createRepeated() => $pb.PbList<DateDescription>();
  @$core.pragma('dart2js:noInline')
  static DateDescription getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DateDescription>(create);
  static DateDescription? _defaultInstance;

  @$pb.TagNumber(1)
  DateFormat get dateFormat => $_getN(0);
  @$pb.TagNumber(1)
  set dateFormat(DateFormat v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDateFormat() => $_has(0);
  @$pb.TagNumber(1)
  void clearDateFormat() => clearField(1);

  @$pb.TagNumber(2)
  TimeFormat get timeFormat => $_getN(1);
  @$pb.TagNumber(2)
  set timeFormat(TimeFormat v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimeFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimeFormat() => clearField(2);
}

class SingleSelect extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SingleSelect', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  SingleSelect._() : super();
  factory SingleSelect({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory SingleSelect.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SingleSelect.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SingleSelect clone() => SingleSelect()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SingleSelect copyWith(void Function(SingleSelect) updates) => super.copyWith((message) => updates(message as SingleSelect)) as SingleSelect; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SingleSelect create() => SingleSelect._();
  SingleSelect createEmptyInstance() => create();
  static $pb.PbList<SingleSelect> createRepeated() => $pb.PbList<SingleSelect>();
  @$core.pragma('dart2js:noInline')
  static SingleSelect getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SingleSelect>(create);
  static SingleSelect? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class MultiSelect extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MultiSelect', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  MultiSelect._() : super();
  factory MultiSelect({
    $core.Iterable<SelectOption>? options,
    $core.bool? disableColor,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (disableColor != null) {
      _result.disableColor = disableColor;
    }
    return _result;
  }
  factory MultiSelect.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiSelect.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiSelect clone() => MultiSelect()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiSelect copyWith(void Function(MultiSelect) updates) => super.copyWith((message) => updates(message as MultiSelect)) as MultiSelect; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MultiSelect create() => MultiSelect._();
  MultiSelect createEmptyInstance() => create();
  static $pb.PbList<MultiSelect> createRepeated() => $pb.PbList<MultiSelect>();
  @$core.pragma('dart2js:noInline')
  static MultiSelect getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiSelect>(create);
  static MultiSelect? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get disableColor => $_getBF(1);
  @$pb.TagNumber(2)
  set disableColor($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisableColor() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisableColor() => clearField(2);
}

class SelectOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOption', createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'color')
    ..hasRequiredFields = false
  ;

  SelectOption._() : super();
  factory SelectOption({
    $core.String? id,
    $core.String? name,
    $core.String? color,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (name != null) {
      _result.name = name;
    }
    if (color != null) {
      _result.color = color;
    }
    return _result;
  }
  factory SelectOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOption clone() => SelectOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOption copyWith(void Function(SelectOption) updates) => super.copyWith((message) => updates(message as SelectOption)) as SelectOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOption create() => SelectOption._();
  SelectOption createEmptyInstance() => create();
  static $pb.PbList<SelectOption> createRepeated() => $pb.PbList<SelectOption>();
  @$core.pragma('dart2js:noInline')
  static SelectOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOption>(create);
  static SelectOption? _defaultInstance;

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
  $core.String get color => $_getSZ(2);
  @$pb.TagNumber(3)
  set color($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => clearField(3);
}

class NumberDescription extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'NumberDescription', createEmptyInstance: create)
    ..e<FlowyMoney>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'money', $pb.PbFieldType.OE, defaultOrMaker: FlowyMoney.CNY, valueOf: FlowyMoney.valueOf, enumValues: FlowyMoney.values)
    ..a<$core.int>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scale', $pb.PbFieldType.OU3)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'symbol')
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'signPositive')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  NumberDescription._() : super();
  factory NumberDescription({
    FlowyMoney? money,
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
  FlowyMoney get money => $_getN(0);
  @$pb.TagNumber(1)
  set money(FlowyMoney v) { setField(1, v); }
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

