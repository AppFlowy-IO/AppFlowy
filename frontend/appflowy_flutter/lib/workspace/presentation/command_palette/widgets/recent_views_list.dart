import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/search_recent_view_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RecentViewsList extends StatelessWidget {
  const RecentViewsList({super.key, required this.onSelected});

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RecentViewsBloc()..add(const RecentViewsEvent.initial()),
      child: BlocBuilder<RecentViewsBloc, RecentViewsState>(
        builder: (context, state) {
          // We remove duplicates by converting the list to a set first
          final List<ViewPB> recentViews =
              state.views.map((e) => e.item).toSet().toList();
          final theme = AppFlowyTheme.of(context);

          return SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    LocaleKeys.sideBar_recent.tr(),
                    style: theme.textStyle.body
                        .enhanced(color: theme.textColorScheme.secondary),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentViews.length,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (_, index) {
                    final view = recentViews[index];
                    final icon = view.icon.value.isNotEmpty
                        ? RawEmojiIconWidget(
                            emoji: view.icon.toEmojiIconData(),
                            emojiSize: 16.0,
                            lineHeight: 20 / 16,
                          )
                        : FlowySvg(
                            view.iconData,
                            size: const Size.square(20),
                            color: theme.iconColorScheme.secondary,
                          );

                    return SearchRecentViewCell(
                      icon: SizedBox.square(
                        dimension: 24,
                        child: Center(child: icon),
                      ),
                      view: view,
                      onSelected: onSelected,
                    );
                  },
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.borderColorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
