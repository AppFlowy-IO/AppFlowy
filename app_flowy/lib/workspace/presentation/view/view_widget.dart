import 'package:flowy_infra_ui/style_widget/styled_hover.dart';
import 'package:flowy_infra_ui/style_widget/styled_icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/presentation/app/app_widget.dart';
import 'package:styled_widget/styled_widget.dart';

class ViewWidgetContext {
  final View view;
  bool isSelected;

  ViewWidgetContext(
    this.view, {
    this.isSelected = false,
  });
}

typedef OpenViewCallback = void Function(View);

class ViewWidget extends StatelessWidget {
  final ViewWidgetContext viewCtx;
  final OpenViewCallback onOpen;
  const ViewWidget({Key? key, required this.viewCtx, required this.onOpen})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = HoverDisplayConfig(hoverColor: Colors.grey.shade200);
    return InkWell(
      onTap: _openView(context),
      child: StyledHover(
        config: config,
        builder: (context, onHover) => _render(context, onHover, config),
      ),
    );
  }

  Widget _render(
      BuildContext context, bool onHover, HoverDisplayConfig config) {
    const double width = 22;
    List<Widget> children = [
      Image(
          fit: BoxFit.cover,
          width: width,
          height: width,
          image: assetImageForViewType(viewCtx.view.viewType)),
      const HSpace(6),
      Text(
        viewCtx.view.name,
        textAlign: TextAlign.start,
        style: const TextStyle(fontSize: 15),
      ),
    ];

    if (onHover) {
      _addedHover(children, width);
    }

    Widget widget = Row(children: children).padding(
      vertical: 5,
      left: AppWidgetSize.expandedPadding,
      right: 5,
    );

    if (viewCtx.isSelected) {
      widget = HoverBackground(child: widget, config: config);
    }

    return widget;
  }

  Function() _openView(BuildContext context) {
    return () => onOpen(viewCtx.view);
  }

  void _addedHover(List<Widget> children, double hoverWidth) {
    children.add(const Spacer());
    children.add(Align(
      alignment: Alignment.center,
      child: StyledMore(
        width: hoverWidth,
        onPressed: () {
          debugPrint('show view setting');
        },
      ),
    ));
  }
}
