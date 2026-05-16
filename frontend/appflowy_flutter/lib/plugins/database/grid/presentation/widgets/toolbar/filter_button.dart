import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../filter/create_filter_list.dart';

class FilterButton extends StatefulWidget {
  const FilterButton({
    super.key,
    required this.toggleExtension,
  });

  final ToggleExtensionNotifier toggleExtension;

  @override
  State<FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<FilterButton> {
  final _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterEditorBloc, FilterEditorState>(
      builder: (context, state) {
        return _wrapPopover(
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: FlowyIconButton(
              tooltipText: LocaleKeys.grid_settings_filter.tr(),
              width: 24,
              height: 24,
              iconPadding: const EdgeInsets.all(3),
              hoverColor: AFThemeExtension.of(context).lightGreyHover,
              icon: const FlowySvg(FlowySvgs.database_filter_s),
              onPressed: () {
                final bloc = context.read<FilterEditorBloc>();
                if (bloc.state.filters.isEmpty) {
                  _popoverController.show();
                } else {
                  widget.toggleExtension.toggle();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _wrapPopover(Widget child) {
    return AppFlowyPopover(
      controller: _popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(200, 300)),
      offset: const Offset(0, 8),
      triggerActions: PopoverTriggerFlags.none,
      child: child,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: CreateDatabaseViewFilterList(
            onTap: () {
              if (!widget.toggleExtension.isToggled) {
                widget.toggleExtension.toggle();
              }
              _popoverController.close();
            },
          ),
        );
      },
    );
  }
}
