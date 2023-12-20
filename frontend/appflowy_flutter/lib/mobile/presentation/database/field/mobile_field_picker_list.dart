import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_option_tile.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileFieldPickerList extends StatefulWidget {
  MobileFieldPickerList({
    super.key,
    required this.selectedFieldId,
    required FieldController fieldController,
    required bool Function(FieldInfo fieldInfo) filterBy,
  }) : fields = fieldController.fieldInfos.where(filterBy).toList();

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
    return Column(
      children: [
        const Center(child: DragHandler()),
        _Header(newFieldId: newFieldId),
        Expanded(
          child: ListView.builder(
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
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.newFieldId});

  final String? newFieldId;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox.square(
              dimension: 36,
              child: IconButton(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                padding: EdgeInsets.zero,
                onPressed: () => context.pop(),
                icon: const FlowySvg(
                  FlowySvgs.arrow_left_s,
                  size: Size.square(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  enableFeedback: true,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                onPressed: () => context.pop(newFieldId),
                child: FlowyText.medium(
                  LocaleKeys.button_save.tr(),
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Center(
          child: FlowyText.medium(
            LocaleKeys.calendar_settings_changeLayoutDateField.tr(),
            fontSize: 16,
          ),
        ),
      ],
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
        field.fieldType.icon(),
        size: const Size.square(20),
      ),
      showTopBorder: showTopBorder,
      onTap: () => onSelect(field.id),
    );
  }
}
