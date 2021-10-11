import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/domain/view_edit.dart';
import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/menu_app.dart';

class ViewWidgetContext {
  final View view;
  ViewWidgetContext(this.view);
  Key valueKey() => ValueKey("${view.id}${view.version}");
}

typedef OpenViewCallback = void Function(View);

// ignore: must_be_immutable
class ViewSectionItem extends StatefulWidget {
  final ViewWidgetContext viewCtx;
  final bool isSelected;
  final OpenViewCallback onOpen;

  ViewSectionItem({
    Key? key,
    required this.viewCtx,
    required this.isSelected,
    required this.onOpen,
  }) : super(key: viewCtx.valueKey());

  @override
  State<ViewSectionItem> createState() => _ViewSectionItemState();
}

class _ViewSectionItemState extends State<ViewSectionItem> {
  bool isOnSelected = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final config = HoverDisplayConfig(hoverColor: theme.bg3);
    return InkWell(
      onTap: _openView(context),
      child: FlowyHover(
        config: config,
        builder: (context, onHover) => _render(context, onHover, config),
        isOnSelected: () => isOnSelected || widget.isSelected,
      ),
    );
  }

  Widget _render(BuildContext context, bool onHover, HoverDisplayConfig config) {
    List<Widget> children = [
      SizedBox(
        width: 16,
        height: 16,
        child: svgForViewType(widget.viewCtx.view.viewType),
      ),
      const HSpace(6),
      FlowyText.regular(
        widget.viewCtx.view.name,
        fontSize: 12,
      ),
    ];

    if (onHover || isOnSelected) {
      children.add(const Spacer());
      children.add(ViewDisclosureButton(
        onTap: () {
          setState(() {
            isOnSelected = true;
          });
        },
        onSelected: (selected) {
          selected.fold(() => null, (action) {
            debugPrint('$action.name');
          });

          setState(() {
            isOnSelected = false;
          });
        },
      ));
    }

    return Container(
      child: Row(children: children).padding(
        left: MenuAppSizes.expandedPadding,
        right: MenuAppSizes.expandedIconPadding,
      ),
      height: 24,
      alignment: Alignment.centerLeft,
    );
  }

  Function() _openView(BuildContext context) {
    return () => widget.onOpen(widget.viewCtx.view);
  }
}

class ViewDisclosureButton extends StatelessWidget {
  final Function(dartz.Option<ViewAction>) onSelected;
  final Function() onTap;
  const ViewDisclosureButton({
    Key? key,
    required this.onSelected,
    required this.onTap,
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

class ViewActionList implements FlowyOverlayDelegate {
  final Function(dartz.Option<ViewAction>) onSelected;
  final BuildContext anchorContext;
  final String _identifier = 'ViewActionList';

  const ViewActionList({required this.anchorContext, required this.onSelected});

  void show(BuildContext buildContext) {
    final items = ViewAction.values.map((action) {
      return ActionItem(
          action: action,
          onSelected: (action) {
            FlowyOverlay.of(buildContext).remove(_identifier);
            onSelected(dartz.some(action));
          });
    }).toList();

    // TODO: make sure the delegate of this wouldn't cause retain cycle
    ListOverlay.showWithAnchor(
      buildContext,
      identifier: _identifier,
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
      anchorContext: anchorContext,
      anchorDirection: AnchorDirection.bottomRight,
      maxWidth: 120,
      maxHeight: 80,
      delegate: this,
    );
  }

  @override
  void didRemove() {
    onSelected(dartz.none());
  }
}

class ActionItem extends StatelessWidget {
  final ViewAction action;
  final Function(ViewAction) onSelected;
  const ActionItem({
    Key? key,
    required this.action,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final config = HoverDisplayConfig(hoverColor: theme.hover);

    return FlowyHover(
      config: config,
      builder: (context, onHover) {
        return GestureDetector(
          onTap: () => onSelected(action),
          child: FlowyText.medium(
            action.name,
            fontSize: 12,
          ).padding(horizontal: 10, vertical: 6),
        );
      },
    );
  }
}
