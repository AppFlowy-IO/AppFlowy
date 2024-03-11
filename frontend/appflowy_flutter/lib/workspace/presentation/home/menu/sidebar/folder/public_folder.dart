import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/menu/sidebar_root_views_bloc.dart';
import 'package:appflowy/workspace/application/sidebar/folder/folder_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/folder/_folder_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/rename_view_dialog.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PublicFolder extends StatelessWidget {
  const PublicFolder({
    super.key,
    required this.views,
    this.isHoverEnabled = true,
  });

  final List<ViewPB> views;
  final bool isHoverEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FolderBloc>(
      create: (context) => FolderBloc(type: FolderCategoryType.public)
        ..add(
          const FolderEvent.initial(),
        ),
      child: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return Column(
            children: [
              FolderHeader(
                title: 'Public',
                onPressed: () => context
                    .read<FolderBloc>()
                    .add(const FolderEvent.expandOrUnExpand()),
                onAdded: (_) {
                  // TODO: lucas.xu insert view into public
                  createViewAndShowRenameDialogIfNeeded(
                    context,
                    LocaleKeys.newPageText.tr(),
                    (viewName, _) {
                      if (viewName.isNotEmpty) {
                        context.read<SidebarRootViewsBloc>().add(
                              SidebarRootViewsEvent.createRootView(
                                viewName,
                                index: 0,
                              ),
                            );

                        context.read<FolderBloc>().add(
                              const FolderEvent.expandOrUnExpand(
                                isExpanded: true,
                              ),
                            );
                      }
                    },
                  );
                },
              ),
              if (state.isExpanded)
                ...views.map(
                  (view) => ViewItem(
                    key: ValueKey(
                      '${FolderCategoryType.public.name} ${view.id}',
                    ),
                    categoryType: FolderCategoryType.public,
                    isFirstChild: view.id == views.first.id,
                    view: view,
                    level: 0,
                    leftPadding: 16,
                    isFeedback: false,
                    onSelected: (view) {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        context.read<TabsBloc>().openTab(view);
                      }

                      context.read<TabsBloc>().openPlugin(view);
                    },
                    onTertiarySelected: (view) =>
                        context.read<TabsBloc>().openTab(view),
                    isHoverEnabled: isHoverEnabled,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
