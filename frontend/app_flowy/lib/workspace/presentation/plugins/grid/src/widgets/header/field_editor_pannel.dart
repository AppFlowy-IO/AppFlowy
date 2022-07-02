import 'dart:typed_data';

import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_type_option.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/type_option_service.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/checkbox.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_type_list.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/date.dart';
import 'field_type_extension.dart';
import 'type_option/multi_select.dart';
import 'type_option/number.dart';
import 'type_option/rich_text.dart';
import 'type_option/single_select.dart';
import 'type_option/url.dart';

typedef UpdateFieldCallback = void Function(Field, Uint8List);
typedef SwitchToFieldCallback = Future<Either<FieldTypeOptionData, FlowyError>> Function(
  String fieldId,
  FieldType fieldType,
);

class FieldEditorPannel extends StatefulWidget {
  final GridFieldContext fieldContext;

  const FieldEditorPannel({
    required this.fieldContext,
    Key? key,
  }) : super(key: key);

  @override
  State<FieldEditorPannel> createState() => _FieldEditorPannelState();
}

class _FieldEditorPannelState extends State<FieldEditorPannel> {
  String? currentOverlayIdentifier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldEditorPannelBloc(widget.fieldContext)..add(const FieldEditorPannelEvent.initial()),
      child: BlocBuilder<FieldEditorPannelBloc, FieldEditorPannelState>(
        builder: (context, state) {
          List<Widget> children = [_switchFieldTypeButton(context, widget.fieldContext.field)];
          final typeOptionWidget = _typeOptionWidget(context: context, state: state);

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
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        hoverColor: theme.hover,
        onTap: () {
          final list = FieldTypeList(onSelectField: (newFieldType) {
            widget.fieldContext.switchToField(newFieldType);
          });
          _showOverlay(context, list);
        },
        leftIcon: svgWidget(field.fieldType.iconName(), color: theme.iconColor),
        rightIcon: svgWidget("grid/more", color: theme.iconColor),
      ),
    );
  }

  Widget? _typeOptionWidget({
    required BuildContext context,
    required FieldEditorPannelState state,
  }) {
    final overlayDelegate = TypeOptionOverlayDelegate(
      showOverlay: _showOverlay,
      hideOverlay: _hideOverlay,
    );

    final builder = _makeTypeOptionBuild(
      typeOptionContext: _makeTypeOptionContext(widget.fieldContext),
      overlayDelegate: overlayDelegate,
    );

    return builder.customWidget;
  }

  void _showOverlay(BuildContext context, Widget child, {VoidCallback? onRemoved}) {
    final identifier = child.toString();
    if (currentOverlayIdentifier != null) {
      FlowyOverlay.of(context).remove(currentOverlayIdentifier!);
    }

    currentOverlayIdentifier = identifier;
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: child,
        constraints: BoxConstraints.loose(const Size(460, 440)),
      ),
      identifier: identifier,
      anchorContext: context,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      anchorOffset: const Offset(-20, 0),
    );
  }

  void _hideOverlay(BuildContext context) {
    if (currentOverlayIdentifier != null) {
      FlowyOverlay.of(context).remove(currentOverlayIdentifier!);
    }
  }
}

abstract class TypeOptionBuilder {
  Widget? get customWidget;
}

TypeOptionBuilder _makeTypeOptionBuild({
  required TypeOptionContext typeOptionContext,
  required TypeOptionOverlayDelegate overlayDelegate,
}) {
  switch (typeOptionContext.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionBuilder(
        typeOptionContext as CheckboxTypeOptionContext,
      );
    case FieldType.DateTime:
      return DateTypeOptionBuilder(
        typeOptionContext as DateTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionBuilder(
        typeOptionContext as SingleSelectTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionBuilder(
        typeOptionContext as MultiSelectTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.Number:
      return NumberTypeOptionBuilder(
        typeOptionContext as NumberTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.RichText:
      return RichTextTypeOptionBuilder(
        typeOptionContext as RichTextTypeOptionContext,
      );

    case FieldType.URL:
      return URLTypeOptionBuilder(
        typeOptionContext as URLTypeOptionContext,
      );
  }
  throw UnimplementedError;
}

TypeOptionContext _makeTypeOptionContext(GridFieldContext fieldContext) {
  switch (fieldContext.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: CheckboxTypeOptionDataBuilder(),
      );
    case FieldType.DateTime:
      return DateTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: DateTypeOptionDataBuilder(),
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: MultiSelectTypeOptionDataBuilder(),
      );
    case FieldType.Number:
      return NumberTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: NumberTypeOptionDataBuilder(),
      );
    case FieldType.RichText:
      return RichTextTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: RichTextTypeOptionDataBuilder(),
      );
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: SingleSelectTypeOptionDataBuilder(),
      );

    case FieldType.URL:
      return URLTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: URLTypeOptionDataBuilder(),
      );
  }

  throw UnimplementedError();
}

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}

typedef TypeOptionData = Uint8List;
typedef TypeOptionDataCallback = void Function(TypeOptionData typeOptionData);
typedef ShowOverlayCallback = void Function(
  BuildContext anchorContext,
  Widget child, {
  VoidCallback? onRemoved,
});
typedef HideOverlayCallback = void Function(BuildContext anchorContext);

class TypeOptionOverlayDelegate {
  ShowOverlayCallback showOverlay;
  HideOverlayCallback hideOverlay;
  TypeOptionOverlayDelegate({
    required this.showOverlay,
    required this.hideOverlay,
  });
}
