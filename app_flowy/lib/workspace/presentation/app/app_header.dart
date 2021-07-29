import 'package:app_flowy/workspace/application/app/app_bloc.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/text_button.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_page.dart';

class AppHeader extends StatelessWidget {
  final App app;
  const AppHeader(
    this.app, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            ExpandableController.of(context,
                    rebuildOnChange: false, required: true)
                ?.toggle();
          },
          child: ExpandableIcon(
            theme: ExpandableThemeData(
              expandIcon: Icons.arrow_drop_up,
              collapseIcon: Icons.arrow_drop_down,
              iconColor: Colors.black,
              iconSize: AppPageSize.expandedIconSize,
              iconPadding: EdgeInsets.zero,
              hasIcon: false,
            ),
          ),
        ),
        HSpace(AppPageSize.expandedIconRightSpace),
        Expanded(
          child: FlowyTextButton(
            app.name,
            onPressed: () {
              debugPrint('show app document');
            },
          ),
        ),
        // FlowyIconButton(
        //   icon: const Icon(Icons.add),
        //   onPressed: () {
        //     debugPrint('add view');
        //   },
        // ),
        PopupMenuButton(
            iconSize: 20,
            tooltip: 'create new view',
            icon: const Icon(Icons.add),
            padding: EdgeInsets.zero,
            onSelected: (viewType) =>
                _createView(viewType as ViewType, context),
            itemBuilder: (context) => menuItemBuilder())
      ],
    );
  }

  List<PopupMenuEntry> menuItemBuilder() {
    return ViewType.values
        .where((element) => element != ViewType.Blank)
        .map((ty) {
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
