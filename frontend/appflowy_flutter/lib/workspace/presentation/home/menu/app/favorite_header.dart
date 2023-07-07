import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_infra/icon_data.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy/workspace/application/app/app_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';

import 'header/add_button.dart';
import 'menu_app.dart';

class FavoriteHeader extends StatelessWidget {
  const FavoriteHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MenuAppSizes.headerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _renderExpandedIcon(context),
          const Text("Favorites"),
        ],
      ),
    );
  }

  Widget _renderExpandedIcon(BuildContext context) {
    return SizedBox(
      width: MenuAppSizes.headerHeight,
      height: MenuAppSizes.headerHeight,
      child: InkWell(
        onTap: () {
          ExpandableController.of(
            context,
            rebuildOnChange: false,
            required: true,
          )?.toggle();
        },
        child: ExpandableIcon(
          theme: ExpandableThemeData(
            expandIcon: FlowyIconData.drop_down_show,
            collapseIcon: FlowyIconData.drop_down_hide,
            iconColor: Theme.of(context).colorScheme.tertiary,
            iconSize: MenuAppSizes.iconSize,
            iconPadding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
            hasIcon: false,
          ),
        ),
      ),
    );
  }
}
