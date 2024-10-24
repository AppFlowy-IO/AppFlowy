import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_item_header.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
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
    return BlocProvider(
      create: (context) =>
          SettingsSitesBloc()..add(const SettingsSitesEvent.initial()),
      child: SettingsBody(
        // i18n
        title: 'Sites',
        children: [
          SettingsCategory(
            title: 'All published pages',
            children: [
              const FlowyDivider(),
              BlocBuilder<SettingsSitesBloc, SettingsSitesState>(
                builder: (context, state) {
                  return SeparatedColumn(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    separatorBuilder: () => const FlowyDivider(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    children: _buildPublishedViewsResult(context, state),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPublishedViewsResult(
    BuildContext context,
    SettingsSitesState state,
  ) {
    final result = state.actionResult;
    if (result != null &&
        result.actionType == SettingsSitesActionType.fetchPublishedViews) {
      if (result.isLoading) {
        return [const CircularProgressIndicator()];
      } else if (result.result?.isFailure == true) {
        final error = result.result?.getFailure();
        // remove the error message.
        return [
          FlowyText.regular(
            'Failed to fetch published pages(${error?.msg})',
            color: Theme.of(context).colorScheme.error,
          ),
        ];
      }
    }

    final publishedViews = state.publishedViews;

    if (publishedViews.isEmpty) {
      return [
        FlowyText.regular(
          'No published pages',
          color: Theme.of(context).hintColor,
        ),
      ];
    }

    return [
      const PublishViewItemHeader(),
      ...publishedViews.map(
        (view) => PublishedViewItem(publishInfoView: view),
      ),
    ];
  }
}
