import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/recent/recent_views_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/command_palette/widgets/recent_view_tile.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
              state.views.reversed.map((e) => e.item).toSet().toList();

          return ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: recentViews.length + 1,
            itemBuilder: (_, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: FlowyText(
                    LocaleKeys.commandPalette_recentHistory.tr(),
                  ),
                );
              }

              final view = recentViews[index - 1];
              final icon = view.icon.value.isNotEmpty
                  ? Text(
                      view.icon.value,
                      style: const TextStyle(fontSize: 18.0),
                    )
                  : FlowySvg(view.iconData, size: const Size.square(20));

              return RecentViewTile(
                icon: icon,
                view: view,
                onSelected: onSelected,
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 0),
          );
        },
      ),
    );
  }
}
