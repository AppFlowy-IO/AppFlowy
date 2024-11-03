import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/publish_info_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef OnSelectedHomePage = void Function(ViewPB view);

class SelectHomePageMenu extends StatefulWidget {
  const SelectHomePageMenu({
    super.key,
    required this.onSelected,
    required this.userProfile,
    required this.workspaceId,
  });

  final OnSelectedHomePage onSelected;
  final UserProfilePB userProfile;
  final String workspaceId;

  @override
  State<SelectHomePageMenu> createState() => _SelectHomePageMenuState();
}

class _SelectHomePageMenuState extends State<SelectHomePageMenu> {
  List<PublishInfoViewPB> source = [];
  List<PublishInfoViewPB> views = [];

  @override
  void initState() {
    super.initState();

    source = context.read<SettingsSitesBloc>().state.publishedViews;
    views = [...source];
  }

  @override
  Widget build(BuildContext context) {
    if (views.isEmpty) {
      return _buildNoPublishedViews();
    }

    return _buildMenu(context);
  }

  Widget _buildNoPublishedViews() {
    return FlowyText.regular(
      LocaleKeys.settings_sites_publishedPage_noPublishedPages.tr(),
      color: Theme.of(context).hintColor,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpaceSearchField(
          width: 240,
          onSearch: (context, value) => _onSearch(value),
        ),
        const VSpace(10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...views.map(
                  (view) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: PublishInfoViewItem(
                      publishInfoView: view,
                      useIntrinsicWidth: false,
                      onTap: () {
                        context.read<SettingsSitesBloc>().add(
                              SettingsSitesEvent.setHomePage(view.info.viewId),
                            );

                        PopoverContainer.of(context).close();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onSearch(String value) {
    setState(() {
      if (value.isEmpty) {
        views = source;
      } else {
        views = source
            .where(
              (view) =>
                  view.view.name.toLowerCase().contains(value.toLowerCase()),
            )
            .toList();
      }
    });
  }
}
