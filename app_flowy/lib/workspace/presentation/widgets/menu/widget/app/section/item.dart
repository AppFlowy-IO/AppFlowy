import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/domain/edit_action/view_edit.dart';
import 'package:app_flowy/workspace/presentation/widgets/dialogs.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/menu_app.dart';

import 'disclosure_action.dart';

// ignore: must_be_immutable
class ViewSectionItem extends StatelessWidget {
  final bool isSelected;
  final View view;
  final void Function(View) onSelected;

  ViewSectionItem({
    Key? key,
    required this.view,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: ValueKey('$view.id/$isSelected'));

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (ctx) => getIt<ViewBloc>(param1: view)..add(const ViewEvent.initial())),
      ],
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (context, state) {
          return InkWell(
            onTap: () => onSelected(context.read<ViewBloc>().state.view),
            child: FlowyHover(
              config: HoverDisplayConfig(hoverColor: theme.bg3),
              builder: (_, onHover) => _render(context, onHover, state),
              isOnSelected: () => state.isEditing || isSelected,
            ),
          );
        },
      ),
    );
  }

  Widget _render(BuildContext context, bool onHover, ViewState state) {
    List<Widget> children = [
      SizedBox(width: 16, height: 16, child: state.view.thumbnail()),
      const HSpace(2),
      Expanded(child: FlowyText.regular(state.view.name, fontSize: 12)),
    ];

    if (onHover || state.isEditing) {
      children.add(
        ViewDisclosureButton(
          onTap: () => context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true)),
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

  void _handleAction(BuildContext context, dartz.Option<ViewDisclosureAction> action) {
    action.foldRight({}, (action, previous) {
      switch (action) {
        case ViewDisclosureAction.rename:
          TextFieldDialog(
            title: 'Rename',
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
