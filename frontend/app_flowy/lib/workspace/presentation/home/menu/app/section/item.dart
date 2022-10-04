import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/application/view/view_ext.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';

import 'disclosure_action.dart';

// ignore: must_be_immutable
class ViewSectionItem extends StatelessWidget {
  final bool isSelected;
  final ViewPB view;
  final void Function(ViewPB) onSelected;

  ViewSectionItem({
    Key? key,
    required this.view,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: ValueKey('$view.hashCode/$isSelected'));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (ctx) =>
                getIt<ViewBloc>(param1: view)..add(const ViewEvent.initial())),
      ],
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          return ViewDisclosureRegion(
              onTap: () => context
                  .read<ViewBloc>()
                  .add(const ViewEvent.setIsEditing(true)),
              onSelected: (action) {
                context
                    .read<ViewBloc>()
                    .add(const ViewEvent.setIsEditing(false));
                _handleAction(context, action);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  onTap: () => onSelected(context.read<ViewBloc>().state.view),
                  child: FlowyHover(
                    style: HoverStyle(hoverColor: theme.bg3),
                    builder: (_, onHover) =>
                        _render(context, onHover, state, theme.iconColor),
                    setSelected: () => state.isEditing || isSelected,
                  ),
                ),
              ));
        },
      ),
    );
  }

  Widget _render(
      BuildContext context, bool onHover, ViewState state, Color iconColor) {
    List<Widget> children = [
      SizedBox(
        width: 16,
        height: 16,
        child: state.view.renderThumbnail(iconColor: iconColor),
      ),
      const HSpace(2),
      Expanded(
        child: FlowyText.regular(
          state.view.name,
          fontSize: 12,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    if (onHover || state.isEditing) {
      children.add(
        ViewDisclosureButton(
          onTap: () =>
              context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true)),
          onSelected: (action) {
            context.read<ViewBloc>().add(const ViewEvent.setIsEditing(false));
            _handleAction(context, action);
          },
        ),
      );
    }

    return SizedBox(
      height: 26,
      child: Row(children: children).padding(
        left: MenuAppSizes.expandedPadding,
        right: MenuAppSizes.headerPadding,
      ),
    );
  }

  void _handleAction(
      BuildContext context, dartz.Option<ViewDisclosureAction> action) {
    action.foldRight({}, (action, previous) {
      switch (action) {
        case ViewDisclosureAction.rename:
          NavigatorTextFieldDialog(
            title: LocaleKeys.disclosureAction_rename.tr(),
            value: context.read<ViewBloc>().state.view.name,
            confirm: (newValue) {
              context.read<ViewBloc>().add(ViewEvent.rename(newValue));
            },
          ).show(context);

          break;
        case ViewDisclosureAction.delete:
          context.read<ViewBloc>().add(const ViewEvent.delete());
          break;
        case ViewDisclosureAction.duplicate:
          context.read<ViewBloc>().add(const ViewEvent.duplicate());
          break;
      }
    });
  }
}

enum ViewDisclosureAction {
  rename,
  delete,
  duplicate,
}

extension ViewDisclosureExtension on ViewDisclosureAction {
  String get name {
    switch (this) {
      case ViewDisclosureAction.rename:
        return LocaleKeys.disclosureAction_rename.tr();
      case ViewDisclosureAction.delete:
        return LocaleKeys.disclosureAction_delete.tr();
      case ViewDisclosureAction.duplicate:
        return LocaleKeys.disclosureAction_duplicate.tr();
    }
  }

  Widget icon(Color iconColor) {
    switch (this) {
      case ViewDisclosureAction.rename:
        return svgWidget('editor/edit', color: iconColor);
      case ViewDisclosureAction.delete:
        return svgWidget('editor/delete', color: iconColor);
      case ViewDisclosureAction.duplicate:
        return svgWidget('editor/copy', color: iconColor);
    }
  }
}
