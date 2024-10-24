import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsSitesPage extends StatelessWidget {
  const SettingsSitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsSitesBloc(),
      child: const _SettingsSitesPageView(),
    );
  }
}

class _SettingsSitesPageView extends StatelessWidget {
  const _SettingsSitesPageView();

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: 'Sites',
      children: [
        BlocBuilder<SettingsSitesBloc, SettingsSitesState>(
          builder: (context, state) {
            return SeparatedColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              separatorBuilder: () => const Divider(),
              children: state.publishedViews
                  .map((view) => PublishedPageItem(publishInfoView: view))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
