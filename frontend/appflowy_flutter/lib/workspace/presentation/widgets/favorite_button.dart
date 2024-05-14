import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ViewFavoriteButton extends StatelessWidget {
  const ViewFavoriteButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final isFavorite = state.views.any((v) => v.id == view.id);
        return Listener(
          onPointerDown: (_) =>
              context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view)),
          child: FlowyTooltip(
            message: isFavorite
                ? LocaleKeys.button_removeFromFavorites.tr()
                : LocaleKeys.button_addToFavorites.tr(),
            child: FlowyHover(
              resetHoverOnRebuild: false,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FlowySvg(
                  isFavorite ? FlowySvgs.favorite_s : FlowySvgs.unfavorite_s,
                  size: const Size.square(18),
                  blendMode: isFavorite ? BlendMode.srcIn : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
