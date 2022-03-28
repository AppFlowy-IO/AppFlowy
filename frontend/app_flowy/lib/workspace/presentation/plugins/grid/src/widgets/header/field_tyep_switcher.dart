import 'dart:typed_data';

import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/date.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/selection.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_type_option.pbserver.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_type_list.dart';

import 'type_option/number.dart';

typedef SelectFieldCallback = void Function(Field, Uint8List);

class FieldTypeSwitcher extends StatefulWidget {
  final SwitchFieldContext switchContext;
  final SelectFieldCallback onSelected;

  const FieldTypeSwitcher({
    required this.switchContext,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<FieldTypeSwitcher> createState() => _FieldTypeSwitcherState();
}

class _FieldTypeSwitcherState extends State<FieldTypeSwitcher> {
  String? currentOverlayIdentifier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FieldTypeSwitchBloc>(param1: widget.switchContext),
      child: BlocBuilder<FieldTypeSwitchBloc, FieldTypeSwitchState>(
        builder: (context, state) {
          List<Widget> children = [_switchFieldTypeButton(context, state.field)];

          final typeOptionWidget = _typeOptionWidget(
            context: context,
            fieldType: state.field.fieldType,
            data: state.typeOptionData,
          );

          if (typeOptionWidget != null) {
            children.add(typeOptionWidget);
          }

          return ListView(
            shrinkWrap: true,
            children: children,
          );
        },
      ),
    );
  }

  Widget _switchFieldTypeButton(BuildContext context, Field field) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(field.fieldType.title(), fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        hoverColor: theme.hover,
        onTap: () {
          final list = FieldTypeList(onSelectField: (fieldType) {
            context.read<FieldTypeSwitchBloc>().add(FieldTypeSwitchEvent.toFieldType(fieldType));
          });
          _showOverlay(context, FieldTypeList.identifier(), list);
        },
        leftIcon: svg(field.fieldType.iconName(), color: theme.iconColor),
        rightIcon: svg("grid/more", color: theme.iconColor),
      ),
    );
  }

  Widget? _typeOptionWidget({
    required BuildContext context,
    required FieldType fieldType,
    required TypeOptionData data,
  }) {
    final delegate = TypeOptionOperationDelegate(
      didUpdateTypeOptionData: (data) {
        context.read<FieldTypeSwitchBloc>().add(FieldTypeSwitchEvent.didUpdateTypeOptionData(data));
      },
      requireToShowOverlay: _showOverlay,
    );
    final builder = _makeTypeOptionBuild(fieldType: fieldType, data: data, delegate: delegate);
    return builder.customWidget;
  }

  void _showOverlay(BuildContext context, String identifier, Widget child) {
    if (currentOverlayIdentifier != null) {
      FlowyOverlay.of(context).remove(currentOverlayIdentifier!);
    }

    currentOverlayIdentifier = identifier;
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: child,
        constraints: BoxConstraints.loose(const Size(240, 400)),
      ),
      identifier: identifier,
      anchorContext: context,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      anchorOffset: const Offset(-20, 0),
    );
  }
}

abstract class TypeOptionBuilder {
  Widget? get customWidget;
}

TypeOptionBuilder _makeTypeOptionBuild({
  required FieldType fieldType,
  required TypeOptionData data,
  required TypeOptionOperationDelegate delegate,
}) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionBuilder(data);
    case FieldType.DateTime:
      return DateTypeOptionBuilder(data, delegate);
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionBuilder(data);
    case FieldType.Number:
      return NumberTypeOptionBuilder(data, delegate);
    case FieldType.RichText:
      return RichTextTypeOptionBuilder(data);
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionBuilder(data);
    default:
      throw UnimplementedError;
  }
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}

typedef TypeOptionData = Uint8List;
typedef TypeOptionDataCallback = void Function(TypeOptionData typeOptionData);
typedef ShowOverlayCallback = void Function(BuildContext anchorContext, String overlayIdentifier, Widget child);

class TypeOptionOperationDelegate {
  TypeOptionDataCallback didUpdateTypeOptionData;
  ShowOverlayCallback requireToShowOverlay;
  TypeOptionOperationDelegate({
    required this.didUpdateTypeOptionData,
    required this.requireToShowOverlay,
  });
}

class RichTextTypeOptionBuilder extends TypeOptionBuilder {
  RichTextTypeOption typeOption;

  RichTextTypeOptionBuilder(TypeOptionData typeOptionData) : typeOption = RichTextTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => null;
}

class CheckboxTypeOptionBuilder extends TypeOptionBuilder {
  CheckboxTypeOption typeOption;

  CheckboxTypeOptionBuilder(TypeOptionData typeOptionData) : typeOption = CheckboxTypeOption.fromBuffer(typeOptionData);

  @override
  Widget? get customWidget => null;
}
