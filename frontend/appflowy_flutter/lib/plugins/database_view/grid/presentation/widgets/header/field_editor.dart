import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_settings_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'field_type_option_editor.dart';

enum FieldEditorPage {
  general,
  details,
}

class FieldEditor extends StatefulWidget {
  final String viewId;
  final FieldController fieldController;
  final FieldPB field;
  final FieldEditorPage initialPage;

  const FieldEditor({
    super.key,
    required this.viewId,
    required this.field,
    required this.fieldController,
    this.initialPage = FieldEditorPage.details,
  });

  @override
  State<StatefulWidget> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<FieldEditor> {
  late FieldEditorPage _currentPage;
  late final TextEditingController textController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    textController = TextEditingController(text: widget.field.name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FieldEditorBloc(
        viewId: widget.viewId,
        field: widget.field,
        fieldController: widget.fieldController,
        loader: FieldTypeOptionLoader(
          viewId: widget.viewId,
          field: widget.field,
        ),
      )..add(const FieldEditorEvent.initial()),
      child: _currentPage == FieldEditorPage.details
          ? _fieldDetails()
          : _fieldGeneral(),
    );
  }

  Widget _fieldGeneral() {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldNameTextField(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            textEditingController: textController,
          ),
          _EditFieldButton(
            onTap: () {
              setState(() => _currentPage = FieldEditorPage.details);
            },
          ),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.toggleVisibility),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.duplicate),
          VSpace(GridSize.typeOptionSeparatorHeight),
          _actionCell(FieldAction.delete),
        ],
      ).padding(all: 8.0),
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

  Widget _actionCell(FieldAction action) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) => FieldActionCell(
        viewId: widget.viewId,
        fieldInfo: state.field,
        action: action,
      ),
    );
  }
}

class _EditFieldButton extends StatelessWidget {
  final void Function()? onTap;
  const _EditFieldButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        leftIcon: const FlowySvg(FlowySvgs.edit_s),
        text: FlowyText.medium(
          LocaleKeys.grid_field_editProperty.tr(),
        ),
        onTap: onTap,
      ),
    );
  }
}

class FieldActionCell extends StatelessWidget {
  final String viewId;
  final FieldInfo fieldInfo;
  final FieldAction action;
  final PopoverMutex? popoverMutex;

  const FieldActionCell({
    super.key,
    required this.viewId,
    required this.fieldInfo,
    required this.action,
    this.popoverMutex,
  });

  @override
  Widget build(BuildContext context) {
    bool enable = true;
    // If the field is primary, delete and duplicate are disabled.
    if (fieldInfo.isPrimary &&
        (action == FieldAction.duplicate || action == FieldAction.delete)) {
      enable = false;
    }

    return FlowyButton(
      disable: !enable,
      text: FlowyText.medium(
        action.title(fieldInfo),
        color: enable ? null : Theme.of(context).disabledColor,
      ),
      onHover: (_) => popoverMutex?.close(),
      onTap: () => action.run(context, viewId, fieldInfo),
      leftIcon: FlowySvg(
        action.icon(fieldInfo),
        size: const Size.square(16),
        color: enable ? null : Theme.of(context).disabledColor,
      ),
    );
  }
}

enum FieldAction {
  toggleVisibility,
  duplicate,
  delete,
}

extension _FieldActionExtension on FieldAction {
  FlowySvgData icon(FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          return FlowySvgs.show_m;
        } else {
          return FlowySvgs.hide_s;
        }
      case FieldAction.duplicate:
        return FlowySvgs.copy_s;
      case FieldAction.delete:
        return FlowySvgs.delete_s;
    }
  }

  String title(FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.toggleVisibility:
        if (fieldInfo.visibility != null &&
            fieldInfo.visibility == FieldVisibility.AlwaysHidden) {
          return LocaleKeys.grid_field_show.tr();
        } else {
          return LocaleKeys.grid_field_hide.tr();
        }
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
    }
  }

  void run(BuildContext context, String viewId, FieldInfo fieldInfo) {
    switch (this) {
      case FieldAction.toggleVisibility:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.toggleFieldVisibility());
        break;
      case FieldAction.duplicate:
        PopoverContainer.of(context).close();
        context
            .read<FieldEditorBloc>()
            .add(const FieldEditorEvent.duplicateField());
        break;
      case FieldAction.delete:
        NavigatorAlertDialog(
          title: LocaleKeys.grid_field_deleteFieldPromptMessage.tr(),
          confirm: () {
            FieldBackendService(
              viewId: viewId,
              fieldId: fieldInfo.id,
            ).deleteField();
          },
        ).show(context);
        PopoverContainer.of(context).close();
        break;
    }
  }
}

class FieldDetailsEditor extends StatefulWidget {
  final String viewId;
  final TextEditingController textEditingController;
  final Function()? onAction;

  const FieldDetailsEditor({
    super.key,
    required this.viewId,
    required this.textEditingController,
    this.onAction,
  });

  @override
  State<StatefulWidget> createState() => _FieldDetailsEditorState();
}

class _FieldDetailsEditorState extends State<FieldDetailsEditor> {
  late PopoverMutex popoverMutex;

  @override
  void initState() {
    popoverMutex = PopoverMutex();
    super.initState();
  }

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      FieldNameTextField(
        popoverMutex: popoverMutex,
        padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 0.0),
        textEditingController: widget.textEditingController,
      ),
      const VSpace(8),
      FieldTypeOptionCell(popoverMutex: popoverMutex),
      const TypeOptionSeparator(),
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
          padding: const EdgeInsets.fromLTRB(8.0, 2.0, 8.0, 0),
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
        if (state.field.isPrimary) {
          return const SizedBox.shrink();
        }
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
        if (state.field.isPrimary) {
          return const SizedBox.shrink();
        }
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

class FieldTypeOptionCell extends StatelessWidget {
  final PopoverMutex popoverMutex;

  const FieldTypeOptionCell({
    super.key,
    required this.popoverMutex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldEditorBloc, FieldEditorState>(
      builder: (context, state) {
        if (state.field.isPrimary) {
          return const SizedBox.shrink();
        }
        final dataController =
            context.read<FieldEditorBloc>().typeOptionController;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: FieldTypeOptionEditor(
            dataController: dataController,
            popoverMutex: popoverMutex,
          ),
        );
      },
    );
  }
}

class FieldNameTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final PopoverMutex? popoverMutex;
  final EdgeInsets padding;
  const FieldNameTextField({
    super.key,
    required this.textEditingController,
    this.popoverMutex,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<FieldNameTextField> createState() => _FieldNameTextFieldState();
}

class _FieldNameTextFieldState extends State<FieldNameTextField> {
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });

    widget.popoverMutex?.listenOnPopoverChanged(() {
      if (focusNode.hasFocus) {
        focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FlowyTextField(
        focusNode: focusNode,
        controller: widget.textEditingController,
        onSubmitted: (_) => PopoverContainer.of(context).close(),
        onChanged: (newName) {
          context
              .read<FieldEditorBloc>()
              .add(FieldEditorEvent.renameField(newName));
        },
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(() {
      if (focusNode.hasFocus) {
        widget.popoverMutex?.close();
      }
    });
    focusNode.dispose();
    super.dispose();
  }
}
