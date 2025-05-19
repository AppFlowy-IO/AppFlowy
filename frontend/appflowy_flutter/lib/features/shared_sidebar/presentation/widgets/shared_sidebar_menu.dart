import 'package:appflowy/features/shared_sidebar/data/local_share_pages_repository.dart';
import 'package:appflowy/features/shared_sidebar/logic/shared_sidebar_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedSidebarMenu extends StatelessWidget {
  const SharedSidebarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return BlocProvider(
      create: (_) => SharedSidebarBloc(repository: LocalSharePagesRepository())
        ..add(const SharedSidebarEvent.init()),
      child: BlocBuilder<SharedSidebarBloc, SharedSidebarState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                state.errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: theme.spacing.s,
                  bottom: theme.spacing.s,
                ),
                child: Text(
                  'Shared',
                  style: theme.textStyle.caption.enhanced(
                    color: theme.textColorScheme.tertiary,
                  ),
                ),
              ),
              AFMenu(
                width: 240,
                children: [
                  ...state.sharedPages.map(
                    (page) => AFTextMenuItem(
                      leading: Icon(
                        Icons.insert_drive_file_outlined,
                        size: 20,
                        color: theme.iconColorScheme.primary,
                      ),
                      title: page.view.name,
                      selected: state.selectedPageId == page.view.id,
                      onTap: () {
                        context.read<SharedSidebarBloc>().add(
                              SharedSidebarEvent.selectPage(
                                pageId: page.view.id,
                              ),
                            );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: theme.spacing.s),
                    child: AFTextMenuItem(
                      leading: Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: theme.iconColorScheme.secondary,
                      ),
                      title: 'More',
                      onTap: () {
                        // TODO: handle more action
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
