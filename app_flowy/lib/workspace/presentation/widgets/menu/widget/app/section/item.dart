import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/view_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/domain/view_ext.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_window.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/domain/view_edit.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/menu_app.dart';

import 'action.dart';

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
            onTap: () {
              onSelected(context.read<ViewBloc>().state.view);
              getIt<HomeStackManager>().setStack(state.view.stackContext());
            },
            child: FlowyHover(
              config: HoverDisplayConfig(hoverColor: theme.bg3),
              builder: (context, onHover) => _render(context, onHover, state),
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
      const HSpace(6),
      FlowyText.regular(state.view.name, fontSize: 12),
    ];

    if (onHover || state.isEditing) {
      children.add(const Spacer());
      children.add(ViewDisclosureButton(
        onTap: () => context.read<ViewBloc>().add(const ViewEvent.setIsEditing(true)),
        onSelected: (action) {
          context.read<ViewBloc>().add(const ViewEvent.setIsEditing(false));
          _handleAction(context, action);
        },
      ));
    }

    return SizedBox(
      height: 24,
      child: Row(children: children).padding(
        left: MenuAppSizes.expandedPadding,
        right: MenuAppSizes.expandedIconPadding,
      ),
    );
  }

  void _handleAction(BuildContext context, dartz.Option<ViewAction> action) {
    action.foldRight({}, (action, previous) {
      switch (action) {
        case ViewAction.rename:
          FlowyPoppuWindow.show(
            context,
            child: ViewRenamePannel(renameCallback: (name) {
              context.read<ViewBloc>().add(ViewEvent.rename(name));
            }),
          );
          break;
        case ViewAction.delete:
          context.read<ViewBloc>().add(const ViewEvent.delete());
          break;
      }
    });
  }
}

// [[Widget: LifeCycle]]
// https://flutterbyexample.com/lesson/stateful-widget-lifecycle

class ViewDisclosureButton extends StatelessWidget {
  final Function() onTap;
  final Function(dartz.Option<ViewAction>) onSelected;
  const ViewDisclosureButton({
    Key? key,
    required this.onTap,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 16,
      onPressed: () {
        onTap();
        ViewActionList(
          anchorContext: context,
          onSelected: onSelected,
        ).show(context);
      },
      icon: svg("editor/details"),
    );
  }
}

class ViewRenamePannel extends StatelessWidget {
  final void Function(String) renameCallback;
  const ViewRenamePannel({Key? key, required this.renameCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 100, height: 200, child: Container(color: Colors.black));
  }
}
