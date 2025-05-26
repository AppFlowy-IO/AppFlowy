import 'package:appflowy/features/shared_section/data/rust_share_pagers_repository.dart';
import 'package:appflowy/features/shared_section/logic/shared_section_bloc.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/refresh_button.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_pages_list.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_error.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_header.dart';
import 'package:appflowy/features/shared_section/presentation/widgets/shared_section_loading.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedSection extends StatelessWidget {
  const SharedSection({
    super.key,
    required this.workspaceId,
  });

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SharedSectionBloc(
        workspaceId: workspaceId,
        repository: RustSharePagesRepository(),
        enablePolling: true,
      )..add(const SharedSectionEvent.init()),
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
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shared header
              const SharedSectionHeader(),

              // Shared pages list
              SharedPagesList(
                sharedPages: state.sharedPages,
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
                    default:
                      // Other actions are not allowed for read-only access
                      break;
                  }
                },
                onSelected: (context, view) {
                  if (HardwareKeyboard.instance.isControlPressed) {
                    context.read<TabsBloc>().openTab(view);
                  }
                  context.read<TabsBloc>().openPlugin(view);
                },
                onTertiarySelected: (context, view) {
                  context.read<TabsBloc>().openTab(view);
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
