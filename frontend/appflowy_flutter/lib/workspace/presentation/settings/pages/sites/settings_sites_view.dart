import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
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
import 'package:easy_localization/easy_localization.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsSitesBloc>(
          create: (context) => SettingsSitesBloc(
            workspaceId: workspaceId,
            user: user,
          )..add(const SettingsSitesEvent.initial()),
        ),
        BlocProvider<UserWorkspaceBloc>(
          create: (context) => UserWorkspaceBloc(userProfile: user)
            ..add(const UserWorkspaceEvent.initial()),
        ),
      ],
      child: const _SettingsSitesPageView(),
    );
  }
}

class _SettingsSitesPageView extends StatelessWidget {
  const _SettingsSitesPageView();

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: LocaleKeys.settings_sites_title.tr(),
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
      title: LocaleKeys.settings_sites_namespaceHeader.tr(),
      description: LocaleKeys.settings_sites_namespaceDescription.tr(),
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
      title: LocaleKeys.settings_sites_publishedPage_title.tr(),
      description: LocaleKeys.settings_sites_publishedPage_description.tr(),
      descriptionColor: Theme.of(context).hintColor,
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
    final publishedViews = state.publishedViews;
    final List<Widget> children = [
      const PublishViewItemHeader(),
    ];

    if (!state.isLoading) {
      if (publishedViews.isEmpty) {
        children.add(
          FlowyText.regular(
            LocaleKeys.settings_sites_publishedPage_emptyHinText.tr(),
            color: Theme.of(context).hintColor,
          ),
        );
      } else {
        children.addAll(
          publishedViews.map(
            (view) => PublishedViewItem(publishInfoView: view),
          ),
        );
      }
    } else {
      children.add(
        const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator.adaptive(strokeWidth: 3),
          ),
        ),
      );
    }

    return children;
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
          message:
              LocaleKeys.settings_sites_error_failedToGeneratePaymentLink.tr(),
          type: ToastificationType.error,
        );
      });
    } else if (type == SettingsSitesActionType.unpublishView &&
        result != null) {
      result.fold((_) {
        showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishSuccessfully.tr(),
        );
      }, (f) {
        Log.error('Failed to unpublish view: ${f.msg}');

        showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishFailed.tr(),
          type: ToastificationType.error,
          description: f.msg,
        );
      });
    } else if (type == SettingsSitesActionType.setHomePage && result != null) {
      result.fold((s) {
        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_success_setHomepageSuccess.tr(),
        );
      }, (f) {
        Log.error('Failed to set homepage: ${f.msg}');

        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_error_setHomepageFailed.tr(),
          type: ToastificationType.error,
        );
      });
    } else if (type == SettingsSitesActionType.removeHomePage &&
        result != null) {
      result.fold((s) {
        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_success_removeHomePageSuccess.tr(),
        );
      }, (f) {
        Log.error('Failed to remove homepage: ${f.msg}');

        showToastNotification(
          context,
          message: LocaleKeys.settings_sites_error_removeHomePageFailed.tr(),
          type: ToastificationType.error,
        );
      });
    }
  }
}
