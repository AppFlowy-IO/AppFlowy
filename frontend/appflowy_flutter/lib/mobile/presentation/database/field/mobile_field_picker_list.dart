import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar_actions.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileFieldPickerList extends StatefulWidget {
  MobileFieldPickerList({
    super.key,
    required this.title,
    required this.selectedFieldId,
    required FieldController fieldController,
    required bool Function(FieldInfo fieldInfo) filterBy,
  }) : fields = fieldController.fieldInfos.where(filterBy).toList();

  final String title;
  final String? selectedFieldId;
  final List<FieldInfo> fields;

  @override
  State<MobileFieldPickerList> createState() => _MobileFieldPickerListState();
}

class _MobileFieldPickerListState extends State<MobileFieldPickerList> {
  String? newFieldId;

  @override
  void initState() {
    super.initState();
    newFieldId = widget.selectedFieldId;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.98,
      minChildSize: 0.98,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            _Header(
              title: widget.title,
              onDone: (context) => context.pop(newFieldId),
            ),
            SingleChildScrollView(
              controller: scrollController,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.fields.length,
                itemBuilder: (context, index) => _FieldButton(
                  field: widget.fields[index],
                  showTopBorder: index == 0,
                  isSelected: widget.fields[index].id == newFieldId,
                  onSelect: (fieldId) => setState(() => newFieldId = fieldId),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Same header as the one in showMobileBottomSheet, but allows popping the
/// sheet with a value.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onDone,
  });

  final String title;
  final void Function(BuildContext context) onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SizedBox(
        height: 44.0,
        child: Stack(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: AppBarBackButton(),
            ),
            Align(
              child: FlowyText.medium(
                title,
                fontSize: 16.0,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppBarDoneButton(
                onTap: () => onDone(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldButton extends StatelessWidget {
  const _FieldButton({
    required this.field,
    required this.isSelected,
    required this.onSelect,
    required this.showTopBorder,
  });

  final FieldInfo field;
  final bool isSelected;
  final void Function(String fieldId) onSelect;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.checkbox(
      text: field.name,
      isSelected: isSelected,
      leftIcon: FlowySvg(
        field.fieldType.svgData,
        size: const Size.square(20),
      ),
      showTopBorder: showTopBorder,
      onTap: () => onSelect(field.id),
    );
  }
}
