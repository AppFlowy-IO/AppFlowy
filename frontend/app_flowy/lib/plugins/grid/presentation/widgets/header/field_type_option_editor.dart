import 'dart:typed_data';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
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
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';
import 'field_type_list.dart';
import 'type_option/builder.dart';

typedef UpdateFieldCallback = void Function(GridFieldPB, Uint8List);
typedef SwitchToFieldCallback
    = Future<Either<FieldTypeOptionDataPB, FlowyError>> Function(
  String fieldId,
  FieldType fieldType,
);

class FieldTypeOptionEditor extends StatefulWidget {
  final TypeOptionDataController dataController;

  const FieldTypeOptionEditor({
    required this.dataController,
    Key? key,
  }) : super(key: key);

  @override
  State<FieldTypeOptionEditor> createState() => _FieldTypeOptionEditorState();
}

class _FieldTypeOptionEditorState extends State<FieldTypeOptionEditor> {
  String? currentOverlayIdentifier;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FieldTypeOptionEditBloc(widget.dataController)
        ..add(const FieldTypeOptionEditEvent.initial()),
      child: BlocBuilder<FieldTypeOptionEditBloc, FieldTypeOptionEditState>(
        builder: (context, state) {
          List<Widget> children = [
            _switchFieldTypeButton(context, widget.dataController.field)
          ];
          final typeOptionWidget =
              _typeOptionWidget(context: context, state: state);

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

  Widget _switchFieldTypeButton(BuildContext context, GridFieldPB field) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(field.fieldType.title(), fontSize: 12),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        hoverColor: theme.hover,
        onTap: () {
          final list = FieldTypeList(onSelectField: (newFieldType) {
            widget.dataController.switchToField(newFieldType);
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
    required FieldTypeOptionEditState state,
  }) {
    final overlayDelegate = TypeOptionOverlayDelegate(
      showOverlay: _showOverlay,
      hideOverlay: _hideOverlay,
    );

    return makeTypeOptionWidget(
      context: context,
      overlayDelegate: overlayDelegate,
      dataController: widget.dataController,
    );
  }

  void _showOverlay(BuildContext context, Widget child,
      {VoidCallback? onRemoved}) {
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

abstract class TypeOptionWidget extends StatelessWidget {
  const TypeOptionWidget({Key? key}) : super(key: key);
}
