import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/plugins/shared/share/publish_color_extension.dart';
import 'package:appflowy/plugins/shared/share/publish_name_generator.dart';
import 'package:appflowy/plugins/shared/share/share_bloc.dart';
import 'package:appflowy/shared/error_code/error_code_map.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublishTab extends StatelessWidget {
  const PublishTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareBloc, ShareState>(
      listener: (context, state) {
        _showToast(context, state);
      },
      builder: (context, state) {
        if (state.isPublished) {
          return _PublishedWidget(
            url: state.url,
            pathName: state.pathName,
            namespace: state.namespace,
            onVisitSite: (url) => afLaunchUrlString(url),
            onUnPublish: () {
              context.read<ShareBloc>().add(const ShareEvent.unPublish());
            },
          );
        } else {
          return _PublishWidget(
            onPublish: (selectedViews) async {
              final id = context.read<ShareBloc>().view.id;
              final publishName = await generatePublishName(
                id,
                state.viewName,
              );

              if (selectedViews.isNotEmpty) {
                Log.info(
                  'Publishing views: ${selectedViews.map((e) => e.name)}',
                );
              }

              if (context.mounted) {
                context.read<ShareBloc>().add(
                      ShareEvent.publish(
                        '',
                        publishName,
                        selectedViews.map((e) => e.id).toList(),
                      ),
                    );
              }
            },
          );
        }
      },
    );
  }

  void _showToast(BuildContext context, ShareState state) {
    if (state.publishResult != null) {
      state.publishResult!.fold(
        (value) => showToastNotification(
          context,
          message: LocaleKeys.publish_publishSuccessfully.tr(),
        ),
        (error) => showToastNotification(
          context,
          message: '${LocaleKeys.publish_publishFailed.tr()}: ${error.code}',
          type: ToastificationType.error,
        ),
      );
    } else if (state.unpublishResult != null) {
      state.unpublishResult!.fold(
        (value) => showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishSuccessfully.tr(),
        ),
        (error) => showToastNotification(
          context,
          message: LocaleKeys.publish_unpublishFailed.tr(),
          description: error.msg,
          type: ToastificationType.error,
        ),
      );
    } else if (state.updatePathNameResult != null) {
      state.updatePathNameResult!.fold(
        (value) => showToastNotification(
          context,
          message: LocaleKeys.settings_sites_success_updatePathNameSuccess.tr(),
        ),
        (error) {
          Log.error('update path name failed: $error');

          showToastNotification(
            context,
            message: LocaleKeys.settings_sites_error_updatePathNameFailed.tr(),
            type: ToastificationType.error,
            description: error.code.publishErrorMessage,
          );
        },
      );
    }
  }
}

class _PublishedWidget extends StatefulWidget {
  const _PublishedWidget({
    required this.url,
    required this.pathName,
    required this.namespace,
    required this.onVisitSite,
    required this.onUnPublish,
  });

  final String url;
  final String pathName;
  final String namespace;
  final void Function(String url) onVisitSite;
  final VoidCallback onUnPublish;

  @override
  State<_PublishedWidget> createState() => _PublishedWidgetState();
}

class _PublishedWidgetState extends State<_PublishedWidget> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.pathName;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(16),
        const _PublishTabHeader(),
        const VSpace(16),
        _PublishUrl(
          namespace: widget.namespace,
          controller: controller,
          onCopy: (_) {
            final url = context.read<ShareBloc>().state.url;

            getIt<ClipboardService>().setData(
              ClipboardServiceData(plainText: url),
            );

            showToastNotification(
              context,
              message: LocaleKeys.grid_url_copy.tr(),
            );
          },
          onSubmitted: (pathName) {
            context.read<ShareBloc>().add(ShareEvent.updatePathName(pathName));
          },
        ),
        const VSpace(16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Spacer(),
            UnPublishButton(
              onUnPublish: widget.onUnPublish,
            ),
            const HSpace(6),
            _buildVisitSiteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitSiteButton() {
    return RoundedTextButton(
      width: 108,
      height: 36,
      onPressed: () {
        final url = context.read<ShareBloc>().state.url;
        widget.onVisitSite(url);
      },
      title: LocaleKeys.shareAction_visitSite.tr(),
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      fillColor: Theme.of(context).colorScheme.primary,
      hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
      textColor: Theme.of(context).colorScheme.onPrimary,
    );
  }
}

class UnPublishButton extends StatelessWidget {
  const UnPublishButton({
    super.key,
    required this.onUnPublish,
  });

  final VoidCallback onUnPublish;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 36,
      child: FlowyButton(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ShareMenuColors.borderColor(context)),
        ),
        radius: BorderRadius.circular(10),
        text: FlowyText.regular(
          lineHeight: 1.0,
          LocaleKeys.shareAction_unPublish.tr(),
          textAlign: TextAlign.center,
        ),
        onTap: onUnPublish,
      ),
    );
  }
}

class _PublishWidget extends StatefulWidget {
  const _PublishWidget({
    required this.onPublish,
  });

  final void Function(List<ViewPB> selectedViews) onPublish;

  @override
  State<_PublishWidget> createState() => _PublishWidgetState();
}

class _PublishWidgetState extends State<_PublishWidget> {
  List<ViewPB> _selectedViews = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(16),
        const _PublishTabHeader(),
        const VSpace(16),
        // if current view is a database, show the database selector
        if (context.read<ShareBloc>().view.layout.isDatabaseView) ...[
          _PublishDatabaseSelector(
            view: context.read<ShareBloc>().view,
            onSelected: (selectedDatabases) {
              _selectedViews = selectedDatabases;
            },
          ),
          const VSpace(16),
        ],
        PublishButton(
          onPublish: () {
            if (context.read<ShareBloc>().view.layout.isDatabaseView) {
              // check if any database is selected
              if (_selectedViews.isEmpty) {
                showToastNotification(
                  context,
                  message: LocaleKeys.publish_noDatabaseSelected.tr(),
                );
                return;
              }
            }

            widget.onPublish(_selectedViews);
          },
        ),
      ],
    );
  }
}

class PublishButton extends StatelessWidget {
  const PublishButton({
    super.key,
    required this.onPublish,
  });

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return PrimaryRoundedButton(
      text: LocaleKeys.shareAction_publish.tr(),
      useIntrinsicWidth: false,
      margin: const EdgeInsets.symmetric(vertical: 9.0),
      fontSize: 14.0,
      figmaLineHeight: 18.0,
      onTap: onPublish,
    );
  }
}

class _PublishTabHeader extends StatelessWidget {
  const _PublishTabHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FlowySvg(FlowySvgs.share_publish_s),
            const HSpace(6),
            FlowyText(LocaleKeys.shareAction_publishToTheWeb.tr()),
          ],
        ),
        const VSpace(4),
        FlowyText.regular(
          LocaleKeys.shareAction_publishToTheWebHint.tr(),
          fontSize: 12,
          maxLines: 3,
          color: Theme.of(context).hintColor,
        ),
      ],
    );
  }
}

class _PublishUrl extends StatefulWidget {
  const _PublishUrl({
    required this.namespace,
    required this.controller,
    required this.onCopy,
    required this.onSubmitted,
  });

  final String namespace;
  final TextEditingController controller;
  final void Function(String url) onCopy;
  final void Function(String url) onSubmitted;

  @override
  State<_PublishUrl> createState() => _PublishUrlState();
}

class _PublishUrlState extends State<_PublishUrl> {
  final focusNode = FocusNode();
  bool showSaveButton = false;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() => showSaveButton = focusNode.hasFocus);

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChanged);
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FlowyTextField(
        autoFocus: false,
        controller: widget.controller,
        focusNode: focusNode,
        enableBorderColor: ShareMenuColors.borderColor(context),
        prefixIcon: _buildPrefixIcon(context),
        suffixIcon: _buildSuffixIcon(context),
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 18.0 / 14.0,
            ),
      ),
    );
  }

  Widget _buildPrefixIcon(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HSpace(8.0),
          Flexible(
            child: FlowyText.regular(
              ShareConstants.buildNamespaceUrl(
                nameSpace: '${widget.namespace}/',
              ),
              fontSize: 14,
              figmaLineHeight: 18.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(6.0),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: VerticalDivider(
              thickness: 1.0,
              width: 1.0,
            ),
          ),
          const HSpace(6.0),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon(BuildContext context) {
    return showSaveButton
        ? _buildSaveButton(context)
        : _buildCopyLinkIcon(context);
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: FlowyButton(
        useIntrinsicWidth: true,
        text: FlowyText.regular(
          LocaleKeys.button_save.tr(),
          figmaLineHeight: 18.0,
        ),
        onTap: () {
          widget.onSubmitted(widget.controller.text);
          focusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildCopyLinkIcon(BuildContext context) {
    return FlowyHover(
      style: const HoverStyle(
        contentMargin: EdgeInsets.all(4),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onCopy(widget.controller.text),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0x141F2329))),
          ),
          child: const FlowySvg(
            FlowySvgs.m_toolbar_link_m,
          ),
        ),
      ),
    );
  }
}

// used to select which database view should be published
class _PublishDatabaseSelector extends StatefulWidget {
  const _PublishDatabaseSelector({
    required this.view,
    required this.onSelected,
  });

  final ViewPB view;
  final void Function(List<ViewPB> selectedDatabases) onSelected;

  @override
  State<_PublishDatabaseSelector> createState() =>
      _PublishDatabaseSelectorState();
}

class _PublishDatabaseSelectorState extends State<_PublishDatabaseSelector> {
  final PropertyValueNotifier<List<(ViewPB, bool)>> _databaseStatus =
      PropertyValueNotifier<List<(ViewPB, bool)>>([]);
  late final _borderColor = Theme.of(context).hintColor.withOpacity(0.3);

  @override
  void initState() {
    super.initState();

    _databaseStatus.addListener(_onDatabaseStatusChanged);
    _databaseStatus.value = context
        .read<DatabaseTabBarBloc>()
        .state
        .tabBars
        .map((e) => (e.view, true))
        .toList();
  }

  void _onDatabaseStatusChanged() {
    final selectedDatabases =
        _databaseStatus.value.where((e) => e.$2).map((e) => e.$1).toList();
    widget.onSelected(selectedDatabases);
  }

  @override
  void dispose() {
    _databaseStatus.removeListener(_onDatabaseStatusChanged);
    _databaseStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
      builder: (context, state) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              side: BorderSide(color: _borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VSpace(10),
              _buildSelectedDatabaseCount(context),
              const VSpace(10),
              _buildDivider(context),
              const VSpace(10),
              ...state.tabBars.map(
                (e) => _buildDatabaseSelector(context, e),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        color: _borderColor,
        thickness: 1,
        height: 1,
      ),
    );
  }

  Widget _buildSelectedDatabaseCount(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _databaseStatus,
      builder: (context, selectedDatabases, child) {
        final count = selectedDatabases.where((e) => e.$2).length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FlowyText(
            LocaleKeys.publish_database.plural(count).tr(),
            color: Theme.of(context).hintColor,
            fontSize: 13,
          ),
        );
      },
    );
  }

  Widget _buildDatabaseSelector(BuildContext context, DatabaseTabBar tabBar) {
    final isPrimaryDatabase = tabBar.view.id == widget.view.id;
    return ValueListenableBuilder(
      valueListenable: _databaseStatus,
      builder: (context, selectedDatabases, child) {
        final isSelected = selectedDatabases.any(
          (e) => e.$1.id == tabBar.view.id && e.$2,
        );
        return _DatabaseSelectorItem(
          tabBar: tabBar,
          isSelected: isSelected,
          isPrimaryDatabase: isPrimaryDatabase,
          onTap: () {
            // unable to deselect the primary database
            if (isPrimaryDatabase) {
              showToastNotification(
                context,
                message:
                    LocaleKeys.publish_unableToDeselectPrimaryDatabase.tr(),
              );
              return;
            }

            // toggle the selection status
            _databaseStatus.value = _databaseStatus.value
                .map(
                  (e) =>
                      e.$1.id == tabBar.view.id ? (e.$1, !e.$2) : (e.$1, e.$2),
                )
                .toList();
          },
        );
      },
    );
  }
}

class _DatabaseSelectorItem extends StatelessWidget {
  const _DatabaseSelectorItem({
    required this.tabBar,
    required this.isSelected,
    required this.onTap,
    required this.isPrimaryDatabase,
  });

  final DatabaseTabBar tabBar;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPrimaryDatabase;

  @override
  Widget build(BuildContext context) {
    Widget child = _buildItem(context);

    if (!isPrimaryDatabase) {
      child = FlowyHover(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );
    } else {
      child = FlowyTooltip(
        message: LocaleKeys.publish_mustSelectPrimaryDatabase.tr(),
        child: MouseRegion(
          cursor: SystemMouseCursors.forbidden,
          child: child,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: child,
    );
  }

  Widget _buildItem(BuildContext context) {
    final svg = isPrimaryDatabase
        ? FlowySvgs.unable_select_s
        : isSelected
            ? FlowySvgs.check_filled_s
            : FlowySvgs.uncheck_s;
    final blendMode = isPrimaryDatabase ? BlendMode.srcIn : null;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          FlowySvg(
            svg,
            blendMode: blendMode,
            size: const Size.square(18),
          ),
          const HSpace(9.0),
          FlowySvg(
            tabBar.view.layout.icon,
            size: const Size.square(16),
          ),
          const HSpace(6.0),
          FlowyText.regular(
            tabBar.view.name,
            fontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
