import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_header.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/domain/domain_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_item.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/published_page/published_view_item_header.dart';
import 'package:appflowy/workspace/presentation/settings/pages/sites/settings_sites_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsSitesPage extends StatelessWidget {
  const SettingsSitesPage({
    super.key,
    required this.workspaceId,
    required this.user,
  });

  final String workspaceId;
  final UserProfilePB user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsSitesBloc(
        workspaceId: workspaceId,
        user: user,
      )..add(const SettingsSitesEvent.initial()),
      child: const _SettingsSitesPageView(),
    );
  }
}

class _SettingsSitesPageView extends StatelessWidget {
  const _SettingsSitesPageView();

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      // i18n
      title: 'Sites',
      autoSeparate: false,
      children: [
        // Domain / Namespace
        _buildNamespaceCategory(context),
        const VSpace(36),
        // All published pages
        _buildPublishedViewsCategory(context),
      ],
    );
  }

  Widget _buildNamespaceCategory(BuildContext context) {
    return SettingsCategory(
      title: 'Namespace',
      description: 'Manage your domain and homepage',
      descriptionColor: Theme.of(context).hintColor,
      children: [
        const FlowyDivider(),
        BlocConsumer<SettingsSitesBloc, SettingsSitesState>(
          listener: _onListener,
          builder: (context, state) {
            return SeparatedColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              separatorBuilder: () => const FlowyDivider(
                padding: EdgeInsets.symmetric(vertical: 12.0),
              ),
              children: [
                const DomainHeader(),
                DomainItem(
                  namespace: state.namespace,
                  homepage: '',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPublishedViewsCategory(BuildContext context) {
    return SettingsCategory(
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
    );
  }

  List<Widget> _buildPublishedViewsResult(
    BuildContext context,
    SettingsSitesState state,
  ) {
    final result = state.actionResult;
    final publishedViews = state.publishedViews;

    if (result != null &&
        result.actionType == SettingsSitesActionType.fetchPublishedViews) {
      if (result.result?.isFailure == true) {
        final error = result.result?.getFailure();
        // remove the error message.
        return [
          FlowyText.regular(
            'Failed to fetch published pages(${error?.msg})',
            color: Theme.of(context).colorScheme.error,
          ),
        ];
      } else if (!result.isLoading && publishedViews.isEmpty) {
        return [
          FlowyText.regular(
            'You have no published pages in this workspace',
            color: Theme.of(context).hintColor,
          ),
        ];
      }
    }

    return [
      const PublishViewItemHeader(),
      ...publishedViews.map(
        (view) => PublishedViewItem(publishInfoView: view),
      ),
    ];
  }

  void _onListener(BuildContext context, SettingsSitesState state) {
    final actionResult = state.actionResult;
    final type = actionResult?.actionType;
    final result = actionResult?.result;
    if (type == SettingsSitesActionType.upgradeSubscription && result != null) {
      result.onFailure((f) {
        Log.error('Failed to generate payment link for Pro Plan: ${f.msg}');

        showToastNotification(
          context,
          message: 'Failed to generate payment link for Pro Plan',
          type: ToastificationType.error,
        );
      });
    }
  }
}
