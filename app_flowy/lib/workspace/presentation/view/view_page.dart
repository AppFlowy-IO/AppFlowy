import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/domain/image.dart';
import 'package:app_flowy/workspace/presentation/app/app_page.dart';
import 'package:styled_widget/styled_widget.dart';

class ViewWidgetContext {
  final View view;

  ViewWidgetContext(this.view);

  Key valueKey() => ValueKey("${view.id}${view.version}");
}

typedef OpenViewCallback = void Function(View);

class ViewPage extends StatelessWidget {
  final ViewWidgetContext viewCtx;
  final bool isSelected;
  final OpenViewCallback onOpen;
  ViewPage(
      {Key? key,
      required this.viewCtx,
      required this.onOpen,
      required this.isSelected})
      : super(key: viewCtx.valueKey());

  @override
  Widget build(BuildContext context) {
    final config = HoverDisplayConfig(hoverColor: Colors.grey.shade200);
    return InkWell(
      onTap: _openView(context),
      child: FlowyHover(
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
      left: AppPageSize.expandedPadding,
      right: 5,
    );

    if (isSelected) {
      widget = FlowyHoverBackground(child: widget, config: config);
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
      child: FlowyMoreButton(
        width: hoverWidth,
        onPressed: () {
          debugPrint('show view setting');
        },
      ),
    ));
  }
}
