import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/toolbar/board_setting_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/toolbar/grid_group.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/toolbar/grid_property.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';

import 'board_toolbar.dart';

class BoardSettingContext {
  final String viewId;
  final FieldController fieldController;
  BoardSettingContext({
    required this.viewId,
    required this.fieldController,
  });

  factory BoardSettingContext.from(final BoardToolbarContext toolbarContext) =>
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
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => BoardSettingBloc(viewId: settingContext.viewId),
      child: BlocListener<BoardSettingBloc, BoardSettingState>(
        listenWhen: (final previous, final current) =>
            previous.selectedAction != current.selectedAction,
        listener: (final context, final state) {
          state.selectedAction.foldLeft(null, (final _, final action) {
            onAction(action, settingContext);
          });
        },
        child: BlocBuilder<BoardSettingBloc, BoardSettingState>(
          builder: (final context, final state) {
            return _renderList();
          },
        ),
      ),
    );
  }

  Widget _renderList() {
    final cells = BoardSettingAction.values.map((final action) {
      return _SettingItem(action: action);
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        itemCount: cells.length,
        separatorBuilder: (final context, final index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        physics: StyledScrollPhysics(),
        itemBuilder: (final BuildContext context, final int index) {
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
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final isSelected = context
        .read<BoardSettingBloc>()
        .state
        .selectedAction
        .foldLeft(false, (final _, final selectedAction) => selectedAction == action);

    return SizedBox(
      height: 30,
      child: FlowyButton(
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        isSelected: isSelected,
        text: FlowyText.medium(
          action.title(),
          color: AFThemeExtension.of(context).textColor,
        ),
        onTap: () {
          context
              .read<BoardSettingBloc>()
              .add(BoardSettingEvent.performAction(action));
        },
        leftIcon: svgWidget(
          action.iconName(),
          color: Theme.of(context).iconTheme.color,
        ),
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
  final PopoverController popoverController;
  final BoardSettingContext settingContext;

  const BoardSettingListPopover({
    final Key? key,
    required this.popoverController,
    required this.settingContext,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _BoardSettingListPopoverState();
}

class _BoardSettingListPopoverState extends State<BoardSettingListPopover> {
  BoardSettingAction? _action;

  @override
  Widget build(final BuildContext context) {
    if (_action != null) {
      switch (_action!) {
        case BoardSettingAction.groups:
          return GridGroupList(
            viewId: widget.settingContext.viewId,
            fieldController: widget.settingContext.fieldController,
            onDismissed: () {
              widget.popoverController.close();
            },
          );
        case BoardSettingAction.properties:
          return GridPropertyList(
            viewId: widget.settingContext.viewId,
            fieldController: widget.settingContext.fieldController,
          );
      }
    }

    return BoardSettingList(
      settingContext: widget.settingContext,
      onAction: (final action, final settingContext) {
        setState(() => _action = action);
      },
    ).padding(all: 6.0);
  }
}
