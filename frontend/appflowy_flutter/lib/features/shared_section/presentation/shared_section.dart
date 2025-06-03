import 'package:appflowy/features/shared_section/data/repositories/local_shared_pages_repository_impl.dart';
import 'package:appflowy/features/shared_section/logic/shared_section_bloc.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/refresh_button.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_pages_list.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_empty.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_error.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_header.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_loading.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class SharedSection extends StatelessWidget {
  const SharedSection({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    // final repository = RustSharePagesRepositoryImpl();
    final repository = LocalSharedPagesRepositoryImpl();

    return BlocProvider(
      create: (_) => SharedSectionBloc(
        workspaceId: workspaceId,
        repository: repository,
        enablePolling: true,
      )..add(const SharedSectionInitEvent()),
      child: BlocBuilder<SharedSectionBloc, SharedSectionState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const SharedSectionLoading();
          }

          if (state.errorMessage.isNotEmpty) {
            return SharedSectionError(errorMessage: state.errorMessage);
          }

          // hide the shared section if there are no shared pages
          if (state.sharedPages.isEmpty) {
            if (UniversalPlatform.isMobile) {
              return const SharedSectionEmpty();
            }
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared header
              SharedSectionHeader(
                onTap: () {
                  // expand or collapse the shared section
                  context.read<SharedSectionBloc>().add(
                        const SharedSectionToggleExpandedEvent(),
                      );
                },
              ),

              // Shared pages list
              if (state.isExpanded)
                SharedPagesList(
                  sharedPages: state.sharedPages,
                  onSetEditing: (context, value) {
                    context.read<ViewBloc>().add(ViewEvent.setIsEditing(value));
                  },
                  onAction: (action, view, data) async {
                    switch (action) {
                      case ViewMoreActionType.favorite:
                      case ViewMoreActionType.unFavorite:
                        context
                            .read<FavoriteBloc>()
                            .add(FavoriteEvent.toggle(view));
                        break;
                      case ViewMoreActionType.openInNewTab:
                        context.read<TabsBloc>().openTab(view);
                        break;
                      case ViewMoreActionType.rename:
                        await NavigatorTextFieldDialog(
                          title: LocaleKeys.disclosureAction_rename.tr(),
                          autoSelectAllText: true,
                          value: view.nameOrDefault,
                          maxLength: 256,
                          onConfirm: (newValue, _) {
                            // can not use bloc here because it has been disposed.
                            ViewBackendService.updateView(
                              viewId: view.id,
                              name: newValue,
                            );
                          },
                        ).show(context);
                        break;
                      case ViewMoreActionType.leaveSharedPage:
                        // show a dialog to confirm the action
                        await showConfirmDialog(
                          context: context,
                          title: 'Remove your own access',
                          description: '',
                          style: ConfirmPopupStyle.cancelAndOk,
                          confirmLabel: 'Remove',
                          onConfirm: () {
                            // todo: remove the access
                          },
                        );
                        break;
                      default:
                        // Other actions are not allowed for read-only access
                        break;
                    }
                  },
                  onSelected: (view) {
                    // if (HardwareKeyboard.instance.isControlPressed) {
                    //   context.read<TabsBloc>().openTab(view);
                    // }
                    // context.read<TabsBloc>().openPlugin(view);
                  },
                  onTertiarySelected: (context) {
                    // context.read<TabsBloc>().openTab(view);
                  },
                ),

              // Refresh button, for debugging only
              if (kDebugMode)
                RefreshSharedSectionButton(
                  onTap: () {
                    context.read<SharedSectionBloc>().add(
                          const SharedSectionEvent.refresh(),
                        );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
