import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoritePinAction extends StatelessWidget {
  const FavoritePinAction({super.key, required this.view});

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    final tooltip = view.isPinned
        ? LocaleKeys.favorite_removeFromSidebar.tr()
        : LocaleKeys.favorite_addToSidebar.tr();
    final icon = FlowySvg(
      view.isPinned
          ? FlowySvgs.favorite_section_unpin_s
          : FlowySvgs.favorite_section_pin_s,
    );
    return FlowyTooltip(
      message: tooltip,
      child: FlowyIconButton(
        width: 24,
        icon: icon,
        onPressed: () {
          view.isPinned
              ? context.read<FavoriteBloc>().add(FavoriteEvent.unpin(view))
              : context.read<FavoriteBloc>().add(FavoriteEvent.pin(view));
        },
      ),
    );
  }
}
