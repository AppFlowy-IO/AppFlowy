import 'package:app_flowy/workspace/domain/edit_action/app_edit.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/flowy_icon_data_icons.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-core-data-model/app.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:dartz/dartz.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import '../menu_app.dart';
import 'add_button.dart';
import 'right_click_action.dart';

class MenuAppHeader extends StatelessWidget {
  final App app;
  const MenuAppHeader(
    this.app, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: MenuAppSizes.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _renderExpandedIcon(context, theme),
          // HSpace(MenuAppSizes.iconPadding),
          _renderTitle(context, theme),
          _renderAddButton(context),
        ],
      ),
    );
  }

  Widget _renderExpandedIcon(BuildContext context, AppTheme theme) {
    return SizedBox(
      width: MenuAppSizes.headerHeight,
      height: MenuAppSizes.headerHeight,
      child: InkWell(
        onTap: () {
          ExpandableController.of(context, rebuildOnChange: false, required: true)?.toggle();
        },
        child: ExpandableIcon(
          theme: ExpandableThemeData(
            expandIcon: FlowyIconData.drop_down_show,
            collapseIcon: FlowyIconData.drop_down_hide,
            iconColor: theme.shader1,
            iconSize: MenuAppSizes.iconSize,
            iconPadding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            hasIcon: false,
          ),
        ),
      ),
    );
  }

  Widget _renderTitle(BuildContext context, AppTheme theme) {
    return Expanded(
      child: BlocListener<AppBloc, AppState>(
        listenWhen: (p, c) => (p.latestCreatedView == null && c.latestCreatedView != null),
        listener: (context, state) {
          final expandableController = ExpandableController.of(context, rebuildOnChange: false, required: true)!;
          if (!expandableController.expanded) {
            expandableController.toggle();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ExpandableController.of(context, rebuildOnChange: false, required: true)?.toggle(),
          onSecondaryTap: () {
            final actionList = AppDisclosureActionSheet(onSelected: (action) => _handleAction(context, action));
            actionList.show(
              context,
              context,
              anchorDirection: AnchorDirection.bottomWithCenterAligned,
            );
          },
          child: BlocSelector<AppBloc, AppState, App>(
            selector: (state) => state.app,
            builder: (context, app) => FlowyText.medium(
              app.name,
              fontSize: 12,
              color: theme.textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderAddButton(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.menuAppHeader_addPageTooltip.tr(),
      child: AddButton(
        onSelected: (viewType) {
          context
              .read<AppBloc>()
              .add(AppEvent.createView(LocaleKeys.menuAppHeader_defaultNewPageName.tr(), "", viewType));
        },
      ).padding(right: MenuAppSizes.headerPadding),
    );
  }

  void _handleAction(BuildContext context, Option<AppDisclosureAction> action) {
    action.fold(() {}, (action) {
      switch (action) {
        case AppDisclosureAction.rename:
          TextFieldDialog(
            title: LocaleKeys.menuAppHeader_renameDialog.tr(),
            value: context.read<AppBloc>().state.app.name,
            confirm: (newValue) {
              context.read<AppBloc>().add(AppEvent.rename(newValue));
            },
          ).show(context);

          break;
        case AppDisclosureAction.delete:
          context.read<AppBloc>().add(const AppEvent.delete());
          break;
      }
    });
  }
}
