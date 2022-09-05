import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/board/application/toolbar/board_setting_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/toolbar/grid_group.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/toolbar/grid_property.dart';
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

import 'board_toolbar.dart';

class BoardSettingContext {
  final String viewId;
  final GridFieldController fieldController;
  BoardSettingContext({
    required this.viewId,
    required this.fieldController,
  });

  factory BoardSettingContext.from(BoardToolbarContext toolbarContext) =>
      BoardSettingContext(
        viewId: toolbarContext.viewId,
        fieldController: toolbarContext.fieldController,
      );
}

class BoardSettingList extends StatelessWidget {
  final BoardSettingContext settingContext;
  final Function(BoardSettingAction, BoardSettingContext) onAction;
  const BoardSettingList({
    required this.settingContext,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BoardSettingBloc(gridId: settingContext.viewId),
      child: BlocListener<BoardSettingBloc, BoardSettingState>(
        listenWhen: (previous, current) =>
            previous.selectedAction != current.selectedAction,
        listener: (context, state) {
          state.selectedAction.foldLeft(null, (_, action) {
            // FlowyOverlay.of(context).remove(identifier());
            onAction(action, settingContext);
          });
        },
        child: BlocBuilder<BoardSettingBloc, BoardSettingState>(
          builder: (context, state) {
            return _renderList();
          },
        ),
      ),
    );
  }

  Widget _renderList() {
    final cells = BoardSettingAction.values.map((action) {
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
  final BoardSettingAction action;

  const _SettingItem({
    required this.action,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.read<AppTheme>();
    final isSelected = context
        .read<BoardSettingBloc>()
        .state
        .selectedAction
        .foldLeft(false, (_, selectedAction) => selectedAction == action);

    return SizedBox(
      height: 30,
      child: FlowyButton(
        isSelected: isSelected,
        text: FlowyText.medium(action.title(),
            fontSize: 12, color: theme.textColor),
        hoverColor: theme.hover,
        onTap: () {
          context
              .read<BoardSettingBloc>()
              .add(BoardSettingEvent.performAction(action));
        },
        leftIcon: svgWidget(action.iconName(), color: theme.iconColor),
      ),
    );
  }
}

extension _GridSettingExtension on BoardSettingAction {
  String iconName() {
    switch (this) {
      case BoardSettingAction.properties:
        return 'grid/setting/properties';
      case BoardSettingAction.groups:
        return 'grid/setting/group';
    }
  }

  String title() {
    switch (this) {
      case BoardSettingAction.properties:
        return LocaleKeys.grid_settings_Properties.tr();
      case BoardSettingAction.groups:
        return LocaleKeys.grid_settings_group.tr();
    }
  }
}

class BoardSettingListPopover extends StatefulWidget {
  final BoardSettingContext settingContext;

  const BoardSettingListPopover({
    Key? key,
    required this.settingContext,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BoardSettingListPopoverState();
}

class _BoardSettingListPopoverState extends State<BoardSettingListPopover> {
  bool _showGridPropertyList = false;

  @override
  Widget build(BuildContext context) {
    if (_showGridPropertyList) {
      return OverlayContainer(
        constraints: BoxConstraints.loose(const Size(260, 400)),
        child: GridPropertyList(
          gridId: widget.settingContext.viewId,
          fieldController: widget.settingContext.fieldController,
        ),
      );
    }

    return OverlayContainer(
      constraints: BoxConstraints.loose(const Size(140, 400)),
      child: BoardSettingList(
        settingContext: widget.settingContext,
        onAction: (action, settingContext) {
          switch (action) {
            case BoardSettingAction.groups:
              break;
            case BoardSettingAction.properties:
              setState(() {
                _showGridPropertyList = true;
              });
              break;
          }
        },
      ),
    );
  }
}
