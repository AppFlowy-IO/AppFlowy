import 'package:app_flowy/workspace/application/grid/setting/setting_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';

class GridSettingContext {
  final String gridId;
  GridSettingContext({
    required this.gridId,
  });
}

class GridSettingList extends StatelessWidget with FlowyOverlayDelegate {
  final GridSettingContext settingContext;
  const GridSettingList({required this.settingContext, Key? key}) : super(key: key);

  void show(BuildContext context) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: this,
        constraints: BoxConstraints.loose(const Size(140, 400)),
      ),
      identifier: identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomRight,
      style: FlowyOverlayStyle(blur: false),
      delegate: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GridSettingBloc(gridId: settingContext.gridId),
      child: BlocListener<GridSettingBloc, GridSettingState>(
        listenWhen: (previous, current) => previous.selectedAction != current.selectedAction,
        listener: (context, state) {
          state.selectedAction.foldLeft(null, (_, action) {
            switch (action) {
              case GridSettingAction.filter:
                // TODO: Handle this case.
                break;
              case GridSettingAction.sortBy:
                // TODO: Handle this case.
                break;
              case GridSettingAction.properties:
                // TODO: Handle this case.
                break;
            }
          });
        },
        child: BlocBuilder<GridSettingBloc, GridSettingState>(
          builder: (context, state) {
            return _renderList();
          },
        ),
      ),
    );
  }

  String identifier() {
    return toString();
  }

  Widget _renderList() {
    final cells = GridSettingAction.values.map((action) {
      return _SettingItem(action: action);
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        itemCount: cells.length,
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        physics: StyledScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final GridSettingAction action;

  const _SettingItem({
    required this.action,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final isSelected = context
        .read<GridSettingBloc>()
        .state
        .selectedAction
        .foldLeft(false, (_, selectedAction) => selectedAction == action);

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        isSelected: isSelected,
        text: FlowyText.medium(action.title(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () {
          context.read<GridSettingBloc>().add(GridSettingEvent.performAction(action));
        },
        leftIcon: svgWidget(action.iconName(), color: theme.iconColor),
      ),
    );
  }
}

extension _GridSettingExtension on GridSettingAction {
  String iconName() {
    switch (this) {
      case GridSettingAction.filter:
        return 'grid/setting/filter';
      case GridSettingAction.sortBy:
        return 'grid/setting/sort';
      case GridSettingAction.properties:
        return 'grid/setting/properties';
    }
  }

  String title() {
    switch (this) {
      case GridSettingAction.filter:
        return LocaleKeys.grid_settings_filter.tr();
      case GridSettingAction.sortBy:
        return LocaleKeys.grid_settings_sortBy.tr();
      case GridSettingAction.properties:
        return LocaleKeys.grid_settings_Properties.tr();
    }
  }
}
