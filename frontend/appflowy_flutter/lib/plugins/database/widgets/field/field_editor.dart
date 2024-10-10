import 'dart:typed_data';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_type_list.dart';
import 'type_option_editor/builder.dart';

enum FieldEditorPage {
  general,
  details,
}

class FieldEditor extends StatefulWidget {
  const FieldEditor({
    super.key,
    required this.viewId,
    required this.fieldInfo,
    required this.fieldController,
    required this.isNewField,
    this.initialPage = FieldEditorPage.details,
    this.onFieldInserted,
  });

  final String viewId;
  final FieldInfo fieldInfo;
  final FieldController fieldController;
  final FieldEditorPage initialPage;
  final void Function(String fieldId)? onFieldInserted;
  final bool isNewField;

  @override
  State<StatefulWidget> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();
  late FieldEditorPage _currentPage;
  late final TextEditingController textController =
      TextEditingController(text: widget.fieldInfo.name);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FieldEditorBloc(
        viewId: widget.viewId,
        fieldInfo: widget.fieldInfo,
        fieldController: widget.fieldController,
        onFieldInserted: widget.onFieldInserted,
        isNew: widget.isNewField,
      ),
      child: _currentPage == FieldEditorPage.general
          ? _fieldGeneral()
          : _fieldDetails(),
    );
  }

  Widget _fieldGeneral() {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _NameAndIcon(
            popoverMutex: popoverMutex,
            textController: textController,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          ),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _EditFieldButton(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            onTap: () {
              setState(() => _currentPage = FieldEditorPage.details);
            },
          ),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.insertLeft),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.insertRight),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.toggleVisibility),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.duplicate),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.clearData),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.delete),
          const TypeOptionSeparator(spacing: 8.0),
          _actionCell(FieldAction.wrap),
          const VSpace(8.0),
        ],
      ),
    );
  }

  Widget _actionCell(FieldAction action) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: action,
          ),
        );
      },
    );
  }

  Widget _fieldDetails() {
    return SizedBox(
      width: 260,
      child: FieldDetailsEditor(
        viewId: widget.viewId,
        textEditingController: textController,
      ),
    );
  }
}

class _EditFieldButton extends StatelessWidget {
  const _EditFieldButton({
    required this.padding,
    this.onTap,
  });

  final EdgeInsetsGeometry padding;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: GridSize.popoverItemHeight,
      padding: padding,
      child: FlowyButton(
        leftIcon: const FlowySvg(FlowySvgs.edit_s),
        text: FlowyText(
          lineHeight: 1.0,
          LocaleKeys.grid_field_editProperty.tr(),
        ),
        onTap: onTap,
      ),
    );
  }
}

class FieldActionCell extends StatelessWidget {
  const FieldActionCell({
    super.key,
    required this.viewId,
    required this.fieldInfo,
    required this.action,
    this.popoverMutex,
  });

  final String viewId;
  final FieldInfo fieldInfo;
  final FieldAction action;
  final PopoverMutex? popoverMutex;

  @override
  Widget build(BuildContext context) {
    bool enable = true;
    // If the field is primary, delete and duplicate are disabled.
    if (fieldInfo.isPrimary &&
        (action == FieldAction.duplicate || action == FieldAction.delete)) {
      enable = false;
    }

    return FlowyButton(
      resetHoverOnRebuild: false,
      disable: !enable,
      text: FlowyText(
        action.title(fieldInfo),
        lineHeight: 1.0,
        color: enable ? null : Theme.of(context).disabledColor,
      ),
      onHover: (_) => popoverMutex?.close(),
      onTap: () => action.run(context, viewId, fieldInfo),
      leftIcon: action.leading(
        fieldInfo,
        enable ? null : Theme.of(context).disabledColor,
      ),
      rightIcon: action.trailing(context, fieldInfo),
    );
  }
}

enum FieldAction {
  insertLeft,
  insertRight,
  toggleVisibility,
  duplicate,
  clearData,
  delete,
  wrap;

  Widget? leading(FieldInfo fieldInfo, Color? color) {
    FlowySvgData? svgData;
    switch (this) {
      case FieldAction.insertLeft:
        svgData = FlowySvgs.arrow_s;
      case FieldAction.insertRight:
        svgData = FlowySvgs.arrow_s;
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          svgData = FlowySvgs.show_m;
        } else {
          svgData = FlowySvgs.hide_s;
        }
      case FieldAction.duplicate:
        svgData = FlowySvgs.copy_s;
      case FieldAction.clearData:
        svgData = FlowySvgs.reload_s;
      case FieldAction.delete:
        svgData = FlowySvgs.delete_s;
      default:
    }

    if (svgData == null) {
      return null;
    }
    final icon = FlowySvg(
      svgData,
      size: const Size.square(16),
      color: color,
    );
    return this == FieldAction.insertRight
        ? Transform.flip(flipX: true, child: icon)
        : icon;
  }

  Widget? trailing(BuildContext context, FieldInfo fieldInfo) {
    if (this == FieldAction.wrap) {
      return Toggle(
        value: fieldInfo.wrapCellContent ?? false,
        onChanged: (_) => context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleWrapCellContent()),
        padding: EdgeInsets.zero,
      );
    }

    return null;
  }

  String title(FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.insertLeft:
        return LocaleKeys.grid_field_insertLeft.tr();
      case FieldAction.insertRight:
        return LocaleKeys.grid_field_insertRight.tr();
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          return LocaleKeys.grid_field_show.tr();
        } else {
          return LocaleKeys.grid_field_hide.tr();
        }
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.clearData:
        return LocaleKeys.grid_field_clear.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
      case FieldAction.wrap:
        return LocaleKeys.grid_field_wrapCellContent.tr();
    }
  }

  void run(BuildContext context, String viewId, FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.insertLeft:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.insertLeft());
        break;
      case FieldAction.insertRight:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.insertRight());
        break;
      case FieldAction.toggleVisibility:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleFieldVisibility());
        break;
      case FieldAction.duplicate:
        PopoverContainer.of(context).close();
        FieldBackendService.duplicateField(
          viewId: viewId,
          fieldId: fieldInfo.id,
        );
        break;
      case FieldAction.clearData:
        PopoverContainer.of(context).closeAll();
        showCancelAndConfirmDialog(
          context: context,
          title: LocaleKeys.grid_field_label.tr(),
          description: LocaleKeys.grid_field_clearFieldPromptMessage.tr(),
          confirmLabel: LocaleKeys.button_confirm.tr(),
          onConfirm: () {
            FieldBackendService.clearField(
              viewId: viewId,
              fieldId: fieldInfo.id,
            );
          },
        );
        break;
      case FieldAction.delete:
        PopoverContainer.of(context).closeAll();
        showConfirmDeletionDialog(
          context: context,
          name: LocaleKeys.grid_field_label.tr(),
          description: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          onConfirm: () {
            FieldBackendService.deleteField(
              viewId: viewId,
              fieldId: fieldInfo.id,
            );
          },
        );
        break;
      case FieldAction.wrap:
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleWrapCellContent());
        break;
    }
  }
}

class FieldDetailsEditor extends StatefulWidget {
  const FieldDetailsEditor({
    super.key,
    required this.viewId,
    required this.textEditingController,
    this.onAction,
  });

  final String viewId;
  final TextEditingController textEditingController;
  final Function()? onAction;

  @override
  State<StatefulWidget> createState() => _FieldDetailsEditorState();
}

class _FieldDetailsEditorState extends State<FieldDetailsEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _NameAndIcon(
        popoverMutex: popoverMutex,
        textController: widget.textEditingController,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      ),
      const VSpace(8.0),
      SwitchFieldButton(popoverMutex: popoverMutex),
      const TypeOptionSeparator(spacing: 8.0),
      Flexible(
        child: FieldTypeOptionEditor(
          viewId: widget.viewId,
          popoverMutex: popoverMutex,
        ),
      ),
      _addFieldVisibilityToggleButton(),
      _addDuplicateFieldButton(),
      _addDeleteFieldButton(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _addFieldVisibilityToggleButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.toggleVisibility,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }

  Widget _addDeleteFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.delete,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }

  Widget _addDuplicateFieldButton() {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 0),
          child: FieldActionCell(
            viewId: widget.viewId,
            fieldInfo: state.field,
            action: FieldAction.duplicate,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }
}

class FieldTypeOptionEditor extends StatelessWidget {
  const FieldTypeOptionEditor({
    super.key,
    required this.viewId,
    required this.popoverMutex,
  });

  final String viewId;
  final PopoverMutex popoverMutex;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        if (state.field.isPrimary) {
          return const SizedBox.shrink();
        }
        final typeOptionEditor = makeTypeOptionEditor(
          context: context,
          viewId: viewId,
          field: state.field.field,
          popoverMutex: popoverMutex,
          onTypeOptionUpdated: (Uint8List typeOptionData) {
            context
                .read<FieldEditorBloc>()
                .add(FieldEditorEvent.updateTypeOption(typeOptionData));
          },
        );

        if (typeOptionEditor == null) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: typeOptionEditor),
            const TypeOptionSeparator(spacing: 8.0),
          ],
        );
      },
    );
  }
}

class _NameAndIcon extends StatelessWidget {
  const _NameAndIcon({
    required this.textController,
    this.padding = EdgeInsets.zero,
    this.popoverMutex,
  });

  final TextEditingController textController;
  final PopoverMutex? popoverMutex;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          FieldEditIconButton(
            popoverMutex: popoverMutex,
          ),
          const HSpace(6),
          Expanded(
            child: FieldNameTextField(
              textController: textController,
              popoverMutex: popoverMutex,
            ),
          ),
        ],
      ),
    );
  }
}

class FieldEditIconButton extends StatefulWidget {
  const FieldEditIconButton({
    super.key,
    this.popoverMutex,
  });

  final PopoverMutex? popoverMutex;

  @override
  State<FieldEditIconButton> createState() => _FieldEditIconButtonState();
}

class _FieldEditIconButtonState extends State<FieldEditIconButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      offset: const Offset(0, 4),
      constraints: BoxConstraints.loose(const Size(360, 432)),
      margin: EdgeInsets.zero,
      direction: PopoverDirection.bottomWithLeftAligned,
      controller: popoverController,
      mutex: widget.popoverMutex,
      child: FlowyIconButton(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          borderRadius: Corners.s8Border,
        ),
        icon: BlocBuilder<FieldEditorBloc, FieldEditorState>(
          builder: (context, state) {
            return FieldIcon(fieldInfo: state.field);
          },
        ),
        width: 32,
        onPressed: () => popoverController.show(),
      ),
      popupBuilder: (popoverContext) {
        return FlowyIconEmojiPicker(
          enableBackgroundColorSelection: false,
          tabs: const [PickerTabType.icon],
          onSelectedIcon: (group, icon, _) {
            String newIcon = "";
            if (group != null && icon != null) {
              newIcon = '${group.name}/${icon.name}';
            }

            context
                .read<FieldEditorBloc>()
                .add(FieldEditorEvent.updateIcon(newIcon));

            PopoverContainer.of(popoverContext).close();
          },
        );
      },
    );
  }
}

class FieldNameTextField extends StatefulWidget {
  const FieldNameTextField({
    super.key,
    required this.textController,
    this.popoverMutex,
  });

  final TextEditingController textController;
  final PopoverMutex? popoverMutex;

  @override
  State<FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<FieldNameTextField> {
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(_onFocusChanged);
    widget.popoverMutex?.addPopoverListener(_onPopoverChanged);
  }

  @override
  void dispose() {
    widget.popoverMutex?.removePopoverListener(_onPopoverChanged);
    focusNode.removeListener(_onFocusChanged);
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyTextField(
      focusNode: focusNode,
      controller: widget.textController,
      onSubmitted: (_) => PopoverContainer.of(context).close(),
      onChanged: (newName) {
        context
            .read<FieldEditorBloc>()
            .add(FieldEditorEvent.renameField(newName));
      },
    );
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus) {
      widget.popoverMutex?.close();
    }
  }

  void _onPopoverChanged() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }
}

class SwitchFieldButton extends StatefulWidget {
  const SwitchFieldButton({
    super.key,
    required this.popoverMutex,
  });

  final PopoverMutex popoverMutex;

  @override
  State<SwitchFieldButton> createState() => _SwitchFieldButtonState();
}

class _SwitchFieldButtonState extends State<SwitchFieldButton> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        if (state.field.isPrimary) {
          return SizedBox(
            height: GridSize.popoverItemHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FlowyTooltip(
                message: LocaleKeys.grid_field_switchPrimaryFieldTooltip.tr(),
                child: FlowyButton(
                  text: FlowyText(
                    state.field.fieldType.i18n,
                    lineHeight: 1.0,
                    color: Theme.of(context).disabledColor,
                  ),
                  leftIcon: FlowySvg(
                    state.field.fieldType.svgData,
                    color: Theme.of(context).disabledColor,
                  ),
                  rightIcon: FlowySvg(
                    FlowySvgs.more_s,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          height: GridSize.popoverItemHeight,
          child: AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(460, 540)),
            triggerActions: PopoverTriggerFlags.hover,
            mutex: widget.popoverMutex,
            controller: _popoverController,
            offset: const Offset(8, 0),
            margin: const EdgeInsets.all(8),
            popupBuilder: (BuildContext popoverContext) {
              return FieldTypeList(
                onSelectField: (newFieldType) {
                  context
                      .read<FieldEditorBloc>()
                      .add(FieldEditorEvent.switchFieldType(newFieldType));
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: FlowyButton(
                onTap: () => _popoverController.show(),
                text: FlowyText(
                  state.field.fieldType.i18n,
                  lineHeight: 1.0,
                ),
                leftIcon: FlowySvg(
                  state.field.fieldType.svgData,
                ),
                rightIcon: const FlowySvg(
                  FlowySvgs.more_s,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
