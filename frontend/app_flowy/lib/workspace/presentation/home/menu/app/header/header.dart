import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/color_extension.dart';
import 'package:flowy_infra/icon_data.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

import '../menu_app.dart';
import 'add_button.dart';

class MenuAppHeader extends StatelessWidget {
  final AppPB app;
  const MenuAppHeader(
    this.app, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MenuAppSizes.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _renderExpandedIcon(context),
          // HSpace(MenuAppSizes.iconPadding),
          _renderTitle(context),
          _renderCreateViewButton(context),
        ],
      ),
    );
  }

  Widget _renderExpandedIcon(BuildContext context) {
    return SizedBox(
      width: MenuAppSizes.headerHeight,
      height: MenuAppSizes.headerHeight,
      child: InkWell(
        onTap: () {
          ExpandableController.of(context,
                  rebuildOnChange: false, required: true)
              ?.toggle();
        },
        child: ExpandableIcon(
          theme: ExpandableThemeData(
            expandIcon: FlowyIconData.drop_down_show,
            collapseIcon: FlowyIconData.drop_down_hide,
            iconColor: Theme.of(context).colorScheme.onSurface,
            iconSize: MenuAppSizes.iconSize,
            iconPadding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            hasIcon: false,
          ),
        ),
      ),
    );
  }

  Widget _renderTitle(BuildContext context) {
    return Expanded(
      child: BlocListener<AppBloc, AppState>(
        listenWhen: (p, c) =>
            (p.latestCreatedView == null && c.latestCreatedView != null),
        listener: (context, state) {
          final expandableController = ExpandableController.of(context,
              rebuildOnChange: false, required: true)!;
          if (!expandableController.expanded) {
            expandableController.toggle();
          }
        },
        child: AppActionList(onSelected: (action) {
          switch (action) {
            case AppDisclosureAction.rename:
              NavigatorTextFieldDialog(
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
        }),
      ),
    );
  }

  Widget _renderCreateViewButton(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.menuAppHeader_addPageTooltip.tr(),
      textStyle: AFThemeExtension.of(context).caption.textColor(Colors.white),
      child: AddButton(
        onSelected: (pluginBuilder) {
          context.read<AppBloc>().add(
                AppEvent.createView(
                  LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
                  pluginBuilder,
                ),
              );
        },
      ).padding(right: MenuAppSizes.headerPadding),
    );
  }
}

enum AppDisclosureAction {
  rename,
  delete,
}

extension AppDisclosureExtension on AppDisclosureAction {
  String get name {
    switch (this) {
      case AppDisclosureAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case AppDisclosureAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case AppDisclosureAction.rename:
        return svgWidget('editor/edit', color: iconColor);
      case AppDisclosureAction.delete:
        return svgWidget('editor/delete', color: iconColor);
    }
  }
}

class AppActionList extends StatelessWidget {
  final Function(AppDisclosureAction) onSelected;
  const AppActionList({
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<DisclosureActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: AppDisclosureAction.values
          .map((action) => DisclosureActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ExpandableController.of(context,
                  rebuildOnChange: false, required: true)
              ?.toggle(),
          onSecondaryTap: () {
            controller.show();
          },
          child: BlocSelector<AppBloc, AppState, AppPB>(
            selector: (state) => state.app,
            builder: (context, app) => FlowyText.medium(
              app.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
      onSelected: (action, controller) {
        onSelected(action.inner);
        controller.close();
      },
    );
  }
}

class DisclosureActionWrapper extends ActionCell {
  final AppDisclosureAction inner;

  DisclosureActionWrapper(this.inner);
  @override
  Widget? icon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.name;
}
