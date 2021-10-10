import 'package:app_flowy/workspace/presentation/widgets/menu/widget/app/app.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/workspace/domain/image.dart';
import 'package:provider/provider.dart';
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
  ViewPage({Key? key, required this.viewCtx, required this.onOpen, required this.isSelected})
      : super(key: viewCtx.valueKey());

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final config = HoverDisplayConfig(hoverColor: theme.bg3);
    return InkWell(
      onTap: _openView(context),
      child: FlowyHover(
        config: config,
        builder: (context, onHover) => _render(context, onHover, config),
      ),
    );
  }

  Widget _render(BuildContext context, bool onHover, HoverDisplayConfig config) {
    List<Widget> children = [
      SizedBox(
        width: 16,
        height: 16,
        child: svgForViewType(viewCtx.view.viewType),
      ),
      const HSpace(6),
      FlowyText.regular(
        viewCtx.view.name,
        fontSize: 12,
      ),
    ];

    if (onHover) {
      children.add(const Spacer());
      children.add(ViewMoreButton(
        width: 16,
        onPressed: () {
          debugPrint('show view setting');
        },
      ));
    }

    Widget widget = Container(
      child: Row(children: children).padding(
        left: AppPageSize.expandedPadding,
        right: 12,
      ),
      height: 24,
      alignment: Alignment.centerLeft,
    );

    if (isSelected) {
      widget = FlowyHoverBackground(child: widget, config: config);
    }

    return widget;
  }

  Function() _openView(BuildContext context) {
    return () => onOpen(viewCtx.view);
  }
}
