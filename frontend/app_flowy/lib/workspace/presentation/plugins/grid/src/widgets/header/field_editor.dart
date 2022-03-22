import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/rounded_input_field.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' hide Row;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class FieldEditor extends StatelessWidget {
  final Field field;
  const FieldEditor({required this.field, Key? key}) : super(key: key);

  static void show(BuildContext context, Field field) {
    final editor = FieldEditor(field: field);
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(child: editor),
      identifier: editor.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithLeftAligned,
      style: FlowyOverlayStyle(blur: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider(
      create: (context) => getIt<FieldEditBloc>(param1: field)..add(const FieldEditEvent.initial()),
      child: Container(
        color: theme.surface,
        constraints: BoxConstraints.loose(const Size(300, 200)),
        child: SingleChildScrollView(
          child: Column(children: [
            const FieldNameTextField(),
            // FieldTypeSwitcher(),
            const VSpace(10),
            FieldOperationList(
              onTap: () {
                FlowyOverlay.of(context).remove(identifier());
              },
            ),
          ]),
        ),
      ),
    );
  }

  String identifier() {
    return toString();
  }
}

class FieldNameTextField extends StatelessWidget {
  const FieldNameTextField({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocBuilder<FieldEditBloc, FieldEditState>(
      buildWhen: ((previous, current) => previous.field.name == current.field.name),
      builder: (context, state) {
        return RoundedInputField(
          height: 36,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          initialValue: state.field.name,
          normalBorderColor: theme.shader4,
          errorBorderColor: theme.red,
          focusBorderColor: theme.main1,
          cursorColor: theme.main1,
          errorText: state.errorText,
          onChanged: (value) {
            context.read<FieldEditBloc>().add(FieldEditEvent.updateFieldName(value));
          },
        );
      },
    );
  }
}

class FieldTypeSwitcher extends StatelessWidget {
  const FieldTypeSwitcher({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return FlowyButton(
      text: FlowyText.medium(context.read<FieldEditBloc>().state.field.name, fontSize: 12),
      hoverColor: theme.hover,
      onTap: () {},
      leftIcon: svg("editor/details", color: theme.iconColor),
    );
  }
}

class FieldOperationList extends StatelessWidget {
  final VoidCallback onTap;
  const FieldOperationList({required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = FieldAction.values
        .map((action) => FieldActionItem(
              action: action,
              onTap: onTap,
            ))
        .toList();
    return GridView(
      // https://api.flutter.dev/flutter/widgets/AnimatedList/shrinkWrap.html
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4.0,
        mainAxisSpacing: 8,
      ),
      children: children,
    );
  }
}

class FieldActionItem extends StatelessWidget {
  final VoidCallback onTap;
  final FieldAction action;
  const FieldActionItem({required this.action, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return FlowyButton(
      text: FlowyText.medium(action.title(), fontSize: 12),
      hoverColor: theme.hover,
      onTap: () {
        action.run(context);
        onTap();
      },
      leftIcon: svg(action.iconName(), color: theme.iconColor),
    );
  }
}

enum FieldAction {
  hide,
  insertLeft,
  duplicate,
  insertRight,
  delete,
}

extension _FieldActionExtension on FieldAction {
  String iconName() {
    switch (this) {
      case FieldAction.hide:
        return 'grid/hide';
      case FieldAction.insertLeft:
        return 'grid/left';
      case FieldAction.insertRight:
        return 'grid/right';
      case FieldAction.duplicate:
        return 'grid/duplicate';
      case FieldAction.delete:
        return 'grid/delete';
    }
  }

  String title() {
    switch (this) {
      case FieldAction.hide:
        return LocaleKeys.grid_field_hide.tr();
      case FieldAction.insertLeft:
        return LocaleKeys.grid_field_insertLeft.tr();
      case FieldAction.insertRight:
        return LocaleKeys.grid_field_insertRight.tr();
      case FieldAction.duplicate:
        return LocaleKeys.grid_field_duplicate.tr();
      case FieldAction.delete:
        return LocaleKeys.grid_field_delete.tr();
    }
  }

  void run(BuildContext context) {
    final bloc = context.read<FieldEditBloc>();

    switch (this) {
      case FieldAction.hide:
        bloc.add(const FieldEditEvent.hideField());
        break;
      case FieldAction.insertLeft:
        bloc.add(const FieldEditEvent.insertField(onLeft: true));
        break;
      case FieldAction.insertRight:
        bloc.add(const FieldEditEvent.insertField(onLeft: false));
        break;
      case FieldAction.duplicate:
        bloc.add(const FieldEditEvent.duplicateField());
        break;
      case FieldAction.delete:
        bloc.add(const FieldEditEvent.deleteField());
        break;
    }
  }
}
