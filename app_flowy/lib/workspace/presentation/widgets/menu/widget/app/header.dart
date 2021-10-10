import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra/flowy_icon_data_icons.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';

class AppHeader extends StatelessWidget {
  final App app;
  const AppHeader(
    this.app, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () {
              ExpandableController.of(context, rebuildOnChange: false, required: true)?.toggle();
            },
            child: ExpandableIcon(
              theme: ExpandableThemeData(
                expandIcon: FlowyIconData.drop_down_show,
                collapseIcon: FlowyIconData.drop_down_hide,
                iconColor: theme.shader1,
                iconSize: AppPageSize.expandedIconSize,
                iconPadding: EdgeInsets.zero,
                hasIcon: false,
              ),
            ),
          ),
          HSpace(AppPageSize.expandedIconRightSpace),
          Expanded(
              child: GestureDetector(
            onTapDown: (_) {
              ExpandableController.of(context, rebuildOnChange: false, required: true)?.toggle();
            },
            child: FlowyText.medium(
              app.name,
              fontSize: 12,
            ),
          )),

          // FlowyIconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () {
          //     debugPrint('add view');
          //     FlowyOverlay.of(context)
          //         .insert(widget: Text('test'), identifier: 'identifier');
          //   },
          // ),
          PopupMenuButton(
              iconSize: 16,
              tooltip: 'create new view',
              icon: svg("home/add"),
              padding: EdgeInsets.zero,
              onSelected: (viewType) => _createView(viewType as ViewType, context),
              itemBuilder: (context) => menuItemBuilder())
        ],
      ),
    );
  }

  List<PopupMenuEntry> menuItemBuilder() {
    return ViewType.values.where((element) => element != ViewType.Blank).map((ty) {
      return PopupMenuItem<ViewType>(
          value: ty,
          child: Row(
            children: <Widget>[Text(ty.name)],
          ));
    }).toList();
  }

  void _createView(ViewType viewType, BuildContext context) {
    context.read<AppBloc>().add(AppEvent.createView("New view", "", viewType));
  }
}
