///
//  Generated code. Do not modify.
//  source: selection_type_option.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cell_entities.pb.dart' as $0;

import 'selection_type_option.pbenum.dart';

export 'selection_type_option.pbenum.dart';

class SingleSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SingleSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  SingleSelectTypeOption._() : super();
  factory SingleSelectTypeOption({
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
  factory SingleSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SingleSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption clone() => SingleSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SingleSelectTypeOption copyWith(void Function(SingleSelectTypeOption) updates) => super.copyWith((message) => updates(message as SingleSelectTypeOption)) as SingleSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption create() => SingleSelectTypeOption._();
  SingleSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<SingleSelectTypeOption> createRepeated() => $pb.PbList<SingleSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static SingleSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SingleSelectTypeOption>(create);
  static SingleSelectTypeOption? _defaultInstance;

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

class MultiSelectTypeOption extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'MultiSelectTypeOption', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'disableColor')
    ..hasRequiredFields = false
  ;

  MultiSelectTypeOption._() : super();
  factory MultiSelectTypeOption({
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
  factory MultiSelectTypeOption.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory MultiSelectTypeOption.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption clone() => MultiSelectTypeOption()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  MultiSelectTypeOption copyWith(void Function(MultiSelectTypeOption) updates) => super.copyWith((message) => updates(message as MultiSelectTypeOption)) as MultiSelectTypeOption; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption create() => MultiSelectTypeOption._();
  MultiSelectTypeOption createEmptyInstance() => create();
  static $pb.PbList<MultiSelectTypeOption> createRepeated() => $pb.PbList<MultiSelectTypeOption>();
  @$core.pragma('dart2js:noInline')
  static MultiSelectTypeOption getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MultiSelectTypeOption>(create);
  static MultiSelectTypeOption? _defaultInstance;

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
    ..e<SelectOptionColor>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'color', $pb.PbFieldType.OE, defaultOrMaker: SelectOptionColor.Purple, valueOf: SelectOptionColor.valueOf, enumValues: SelectOptionColor.values)
    ..hasRequiredFields = false
  ;

  SelectOption._() : super();
  factory SelectOption({
    $core.String? id,
    $core.String? name,
    SelectOptionColor? color,
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
  SelectOptionColor get color => $_getN(2);
  @$pb.TagNumber(3)
  set color(SelectOptionColor v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasColor() => $_has(2);
  @$pb.TagNumber(3)
  void clearColor() => clearField(3);
}

enum SelectOptionChangesetPayload_OneOfInsertOption {
  insertOption, 
  notSet
}

enum SelectOptionChangesetPayload_OneOfUpdateOption {
  updateOption, 
  notSet
}

enum SelectOptionChangesetPayload_OneOfDeleteOption {
  deleteOption, 
  notSet
}

class SelectOptionChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SelectOptionChangesetPayload_OneOfInsertOption> _SelectOptionChangesetPayload_OneOfInsertOptionByTag = {
    2 : SelectOptionChangesetPayload_OneOfInsertOption.insertOption,
    0 : SelectOptionChangesetPayload_OneOfInsertOption.notSet
  };
  static const $core.Map<$core.int, SelectOptionChangesetPayload_OneOfUpdateOption> _SelectOptionChangesetPayload_OneOfUpdateOptionByTag = {
    3 : SelectOptionChangesetPayload_OneOfUpdateOption.updateOption,
    0 : SelectOptionChangesetPayload_OneOfUpdateOption.notSet
  };
  static const $core.Map<$core.int, SelectOptionChangesetPayload_OneOfDeleteOption> _SelectOptionChangesetPayload_OneOfDeleteOptionByTag = {
    4 : SelectOptionChangesetPayload_OneOfDeleteOption.deleteOption,
    0 : SelectOptionChangesetPayload_OneOfDeleteOption.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionChangesetPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..oo(2, [4])
    ..aOM<$0.CellIdentifierPayload>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellIdentifier', subBuilder: $0.CellIdentifierPayload.create)
    ..aOM<SelectOption>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertOption', subBuilder: SelectOption.create)
    ..aOM<SelectOption>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateOption', subBuilder: SelectOption.create)
    ..aOM<SelectOption>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteOption', subBuilder: SelectOption.create)
    ..hasRequiredFields = false
  ;

  SelectOptionChangesetPayload._() : super();
  factory SelectOptionChangesetPayload({
    $0.CellIdentifierPayload? cellIdentifier,
    SelectOption? insertOption,
    SelectOption? updateOption,
    SelectOption? deleteOption,
  }) {
    final _result = create();
    if (cellIdentifier != null) {
      _result.cellIdentifier = cellIdentifier;
    }
    if (insertOption != null) {
      _result.insertOption = insertOption;
    }
    if (updateOption != null) {
      _result.updateOption = updateOption;
    }
    if (deleteOption != null) {
      _result.deleteOption = deleteOption;
    }
    return _result;
  }
  factory SelectOptionChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPayload clone() => SelectOptionChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionChangesetPayload copyWith(void Function(SelectOptionChangesetPayload) updates) => super.copyWith((message) => updates(message as SelectOptionChangesetPayload)) as SelectOptionChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPayload create() => SelectOptionChangesetPayload._();
  SelectOptionChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<SelectOptionChangesetPayload> createRepeated() => $pb.PbList<SelectOptionChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionChangesetPayload>(create);
  static SelectOptionChangesetPayload? _defaultInstance;

  SelectOptionChangesetPayload_OneOfInsertOption whichOneOfInsertOption() => _SelectOptionChangesetPayload_OneOfInsertOptionByTag[$_whichOneof(0)]!;
  void clearOneOfInsertOption() => clearField($_whichOneof(0));

  SelectOptionChangesetPayload_OneOfUpdateOption whichOneOfUpdateOption() => _SelectOptionChangesetPayload_OneOfUpdateOptionByTag[$_whichOneof(1)]!;
  void clearOneOfUpdateOption() => clearField($_whichOneof(1));

  SelectOptionChangesetPayload_OneOfDeleteOption whichOneOfDeleteOption() => _SelectOptionChangesetPayload_OneOfDeleteOptionByTag[$_whichOneof(2)]!;
  void clearOneOfDeleteOption() => clearField($_whichOneof(2));

  @$pb.TagNumber(1)
  $0.CellIdentifierPayload get cellIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set cellIdentifier($0.CellIdentifierPayload v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellIdentifierPayload ensureCellIdentifier() => $_ensure(0);

  @$pb.TagNumber(2)
  SelectOption get insertOption => $_getN(1);
  @$pb.TagNumber(2)
  set insertOption(SelectOption v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasInsertOption() => $_has(1);
  @$pb.TagNumber(2)
  void clearInsertOption() => clearField(2);
  @$pb.TagNumber(2)
  SelectOption ensureInsertOption() => $_ensure(1);

  @$pb.TagNumber(3)
  SelectOption get updateOption => $_getN(2);
  @$pb.TagNumber(3)
  set updateOption(SelectOption v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasUpdateOption() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdateOption() => clearField(3);
  @$pb.TagNumber(3)
  SelectOption ensureUpdateOption() => $_ensure(2);

  @$pb.TagNumber(4)
  SelectOption get deleteOption => $_getN(3);
  @$pb.TagNumber(4)
  set deleteOption(SelectOption v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeleteOption() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleteOption() => clearField(4);
  @$pb.TagNumber(4)
  SelectOption ensureDeleteOption() => $_ensure(3);
}

enum SelectOptionCellChangesetPayload_OneOfInsertOptionId {
  insertOptionId, 
  notSet
}

enum SelectOptionCellChangesetPayload_OneOfDeleteOptionId {
  deleteOptionId, 
  notSet
}

class SelectOptionCellChangesetPayload extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, SelectOptionCellChangesetPayload_OneOfInsertOptionId> _SelectOptionCellChangesetPayload_OneOfInsertOptionIdByTag = {
    2 : SelectOptionCellChangesetPayload_OneOfInsertOptionId.insertOptionId,
    0 : SelectOptionCellChangesetPayload_OneOfInsertOptionId.notSet
  };
  static const $core.Map<$core.int, SelectOptionCellChangesetPayload_OneOfDeleteOptionId> _SelectOptionCellChangesetPayload_OneOfDeleteOptionIdByTag = {
    3 : SelectOptionCellChangesetPayload_OneOfDeleteOptionId.deleteOptionId,
    0 : SelectOptionCellChangesetPayload_OneOfDeleteOptionId.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionCellChangesetPayload', createEmptyInstance: create)
    ..oo(0, [2])
    ..oo(1, [3])
    ..aOM<$0.CellIdentifierPayload>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cellIdentifier', subBuilder: $0.CellIdentifierPayload.create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'insertOptionId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'deleteOptionId')
    ..hasRequiredFields = false
  ;

  SelectOptionCellChangesetPayload._() : super();
  factory SelectOptionCellChangesetPayload({
    $0.CellIdentifierPayload? cellIdentifier,
    $core.String? insertOptionId,
    $core.String? deleteOptionId,
  }) {
    final _result = create();
    if (cellIdentifier != null) {
      _result.cellIdentifier = cellIdentifier;
    }
    if (insertOptionId != null) {
      _result.insertOptionId = insertOptionId;
    }
    if (deleteOptionId != null) {
      _result.deleteOptionId = deleteOptionId;
    }
    return _result;
  }
  factory SelectOptionCellChangesetPayload.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionCellChangesetPayload.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionCellChangesetPayload clone() => SelectOptionCellChangesetPayload()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionCellChangesetPayload copyWith(void Function(SelectOptionCellChangesetPayload) updates) => super.copyWith((message) => updates(message as SelectOptionCellChangesetPayload)) as SelectOptionCellChangesetPayload; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellChangesetPayload create() => SelectOptionCellChangesetPayload._();
  SelectOptionCellChangesetPayload createEmptyInstance() => create();
  static $pb.PbList<SelectOptionCellChangesetPayload> createRepeated() => $pb.PbList<SelectOptionCellChangesetPayload>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionCellChangesetPayload getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionCellChangesetPayload>(create);
  static SelectOptionCellChangesetPayload? _defaultInstance;

  SelectOptionCellChangesetPayload_OneOfInsertOptionId whichOneOfInsertOptionId() => _SelectOptionCellChangesetPayload_OneOfInsertOptionIdByTag[$_whichOneof(0)]!;
  void clearOneOfInsertOptionId() => clearField($_whichOneof(0));

  SelectOptionCellChangesetPayload_OneOfDeleteOptionId whichOneOfDeleteOptionId() => _SelectOptionCellChangesetPayload_OneOfDeleteOptionIdByTag[$_whichOneof(1)]!;
  void clearOneOfDeleteOptionId() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $0.CellIdentifierPayload get cellIdentifier => $_getN(0);
  @$pb.TagNumber(1)
  set cellIdentifier($0.CellIdentifierPayload v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCellIdentifier() => $_has(0);
  @$pb.TagNumber(1)
  void clearCellIdentifier() => clearField(1);
  @$pb.TagNumber(1)
  $0.CellIdentifierPayload ensureCellIdentifier() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get insertOptionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set insertOptionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInsertOptionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearInsertOptionId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get deleteOptionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set deleteOptionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDeleteOptionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDeleteOptionId() => clearField(3);
}

class SelectOptionContext extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SelectOptionContext', createEmptyInstance: create)
    ..pc<SelectOption>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'options', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..pc<SelectOption>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'selectOptions', $pb.PbFieldType.PM, subBuilder: SelectOption.create)
    ..hasRequiredFields = false
  ;

  SelectOptionContext._() : super();
  factory SelectOptionContext({
    $core.Iterable<SelectOption>? options,
    $core.Iterable<SelectOption>? selectOptions,
  }) {
    final _result = create();
    if (options != null) {
      _result.options.addAll(options);
    }
    if (selectOptions != null) {
      _result.selectOptions.addAll(selectOptions);
    }
    return _result;
  }
  factory SelectOptionContext.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SelectOptionContext.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SelectOptionContext clone() => SelectOptionContext()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SelectOptionContext copyWith(void Function(SelectOptionContext) updates) => super.copyWith((message) => updates(message as SelectOptionContext)) as SelectOptionContext; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SelectOptionContext create() => SelectOptionContext._();
  SelectOptionContext createEmptyInstance() => create();
  static $pb.PbList<SelectOptionContext> createRepeated() => $pb.PbList<SelectOptionContext>();
  @$core.pragma('dart2js:noInline')
  static SelectOptionContext getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SelectOptionContext>(create);
  static SelectOptionContext? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SelectOption> get options => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<SelectOption> get selectOptions => $_getList(1);
}

