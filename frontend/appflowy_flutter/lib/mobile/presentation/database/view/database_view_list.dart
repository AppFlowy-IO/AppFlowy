import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/plugins/database_view/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

import 'database_view_layout.dart';

/// [MobileDatabaseViewList] shows a list of all the views in the database and
/// adds a button to create a new database view.
class MobileDatabaseViewList extends StatelessWidget {
  const MobileDatabaseViewList({super.key, required this.views});

  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final children = [
          ...views.map((view) => MobileDatabaseViewListButton(view: view)),
          const VSpace(20),
          const MobileNewDatabaseViewButton(),
        ];

        return Column(
          children: children,
        );
      },
    );
  }
}

@visibleForTesting
class MobileDatabaseViewListButton extends StatelessWidget {
  const MobileDatabaseViewListButton({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: view.name,
      onTap: () {},
      leftIcon: _buildViewIconButton(context, view),
      trailing: FlowySvg(
        FlowySvgs.three_dots_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
    );
  }

  Widget _buildViewIconButton(BuildContext context, ViewPB view) {
    return view.icon.value.isNotEmpty
        ? EmojiText(
            emoji: view.icon.value,
            fontSize: 16.0,
          )
        : SizedBox.square(
            dimension: 20.0,
            child: view.defaultIcon(),
          );
  }
}

class MobileNewDatabaseViewButton extends StatelessWidget {
  const MobileNewDatabaseViewButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_settings_createView.tr(),
      textColor: Theme.of(context).hintColor,
      leftIcon: FlowySvg(
        FlowySvgs.add_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      trailing: FlowySvg(
        FlowySvgs.three_dots_s,
        size: const Size.square(20),
        color: Theme.of(context).hintColor,
      ),
      onTap: () {},
    );
  }
}

class MobileCreateDatabaseView extends StatefulWidget {
  const MobileCreateDatabaseView({super.key});

  @override
  State<MobileCreateDatabaseView> createState() =>
      _MobileCreateDatabaseViewState();
}

class _MobileCreateDatabaseViewState extends State<MobileCreateDatabaseView> {
  late final TextEditingController controller;
  DatabaseLayoutPB layoutType = DatabaseLayoutPB.Grid;
  String icon = "";

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: LocaleKeys.grid_title_placeholder.tr());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyOptionTile.textField(
          controller: controller,
          leftIcon: _buildViewIcon(),
        ),
        const VSpace(20),
        DatabaseViewLayoutPicker(
          selectedLayout: DatabaseLayoutPB.Grid,
          onSelect: (layout) {},
        ),
      ],
    );
  }

  Widget _buildViewIcon() {
    final viewIcon = icon.isNotEmpty
        ? EmojiText(
            emoji: icon,
            fontSize: 16.0,
          )
        : SizedBox.square(
            dimension: 18.0,
            child: FlowySvg(layoutType.icon),
          );
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        width: 36,
        height: 36,
        child: Center(child: viewIcon),
      ),
    );
  }
}
