import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';

import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => getIt<ViewBloc>(param1: view)
            ..add(
              const ViewEvent.initial(),
            ),
        ),
      ],
      child: BlocBuilder<ViewBloc, ViewState>(
        builder: (blocContext, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: InkWell(
              onTap: () => onSelected(blocContext.read<ViewBloc>().state.view),
              child: FlowyHover(
                style: HoverStyle(
                  hoverColor: Theme.of(context).colorScheme.secondary,
                ),
                // If current state.isEditing is true, the hover should not
                // rebuild when onEnter/onExit events happened.
                buildWhenOnHover: () => !state.isEditing,
                builder: (_, onHover) => _render(
                  blocContext,
                  onHover,
                  state,
                ),
                isSelected: () => state.isEditing || isSelected,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _render(
    BuildContext blocContext,
    bool onHover,
    ViewState state,
  ) {
    final List<Widget> children = [
      SizedBox(
        width: 16,
        height: 16,
        child: state.view.renderThumbnail(),
      ),
      const HSpace(2),
      Expanded(
        child: FlowyText.regular(
          state.view.name,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];

    if (onHover || state.isEditing) {
      children.add(
        ViewDisclosureButton(
          onEdit: (isEdit) =>
              blocContext.read<ViewBloc>().add(ViewEvent.setIsEditing(isEdit)),
          onAction: (action) {
            switch (action) {
              case ViewDisclosureAction.rename:
                NavigatorTextFieldDialog(
                  title: LocaleKeys.disclosureAction_rename.tr(),
                  value: blocContext.read<ViewBloc>().state.view.name,
                  confirm: (newValue) {
                    blocContext
                        .read<ViewBloc>()
                        .add(ViewEvent.rename(newValue));
                  },
                ).show(blocContext);

                break;
              case ViewDisclosureAction.delete:
                blocContext.read<ViewBloc>().add(const ViewEvent.delete());
                break;
              case ViewDisclosureAction.duplicate:
                blocContext.read<ViewBloc>().add(const ViewEvent.duplicate());
                break;
            }
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
        return const FlowySvg(name: 'editor/edit');
      case ViewDisclosureAction.delete:
        return const FlowySvg(name: 'editor/delete');
      case ViewDisclosureAction.duplicate:
        return const FlowySvg(name: 'editor/copy');
    }
  }
}

class ViewDisclosureButton extends StatelessWidget {
  final Function(bool) onEdit;
  final Function(ViewDisclosureAction) onAction;
  const ViewDisclosureButton({
    required this.onEdit,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ViewDisclosureActionWrapper>(
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: ViewDisclosureAction.values
          .map((action) => ViewDisclosureActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return FlowyIconButton(
          hoverColor: Colors.transparent,
          iconPadding: const EdgeInsets.all(5),
          width: 26,
          icon: svgWidget(
            "editor/details",
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () {
            onEdit(true);
            controller.show();
          },
        );
      },
      onSelected: (action, controller) {
        onEdit(false);
        onAction(action.inner);
        controller.close();
      },
      onClosed: () {
        onEdit(false);
      },
    );
  }
}

class ViewDisclosureActionWrapper extends ActionCell {
  final ViewDisclosureAction inner;

  ViewDisclosureActionWrapper(this.inner);
  @override
  Widget? leftIcon(Color iconColor) => inner.icon(iconColor);

  @override
  String get name => inner.name;
}
