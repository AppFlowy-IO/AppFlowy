import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_filter_list.dart';
import 'filter_menu_item.dart';

class FilterMenu extends StatelessWidget {
  const FilterMenu({
    super.key,
    required this.fieldController,
  });

  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilterEditorBloc(
        viewId: fieldController.viewId,
        fieldController: fieldController,
      ),
      child: BlocBuilder<FilterEditorBloc, FilterEditorState>(
        buildWhen: (previous, current) {
          final previousIds = previous.filters.map((e) => e.filterId).toList();
          final currentIds = current.filters.map((e) => e.filterId).toList();
          return !listEquals(previousIds, currentIds);
        },
        builder: (context, state) {
          final List<Widget> children = [];
          children.addAll(
            state.filters
                .map(
                  (filter) => FilterMenuItem(
                    key: ValueKey(filter.filterId),
                    filterId: filter.filterId,
                    fieldType: state.fields
                        .firstWhere(
                          (element) => element.id == filter.fieldId,
                        )
                        .fieldType,
                  ),
                )
                .toList(),
          );

          if (state.fields.isNotEmpty) {
            children.add(
              AddFilterButton(
                viewId: state.viewId,
              ),
            );
          }

          return Wrap(
            spacing: 6,
            runSpacing: 4,
            children: children,
          );
        },
      ),
    );
  }
}

class AddFilterButton extends StatefulWidget {
  const AddFilterButton({required this.viewId, super.key});

  final String viewId;

  @override
  State<AddFilterButton> createState() => _AddFilterButtonState();
}

class _AddFilterButtonState extends State<AddFilterButton> {
  final PopoverController popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return wrapPopover(
      SizedBox(
        height: 28,
        child: FlowyButton(
          text: FlowyText(
            lineHeight: 1.0,
            LocaleKeys.grid_settings_addFilter.tr(),
            color: AFThemeExtension.of(context).textColor,
          ),
          useIntrinsicWidth: true,
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          leftIcon: FlowySvg(
            FlowySvgs.add_s,
            color: Theme.of(context).iconTheme.color,
          ),
          onTap: () => popoverController.show(),
        ),
      ),
    );
  }

  Widget wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: CreateDatabaseViewFilterList(
            onTap: () => popoverController.close(),
          ),
        );
      },
    );
  }
}
