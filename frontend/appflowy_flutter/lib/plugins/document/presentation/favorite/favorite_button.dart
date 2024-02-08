import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy/workspace/application/favorite/favorite_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentFavoriteButton extends StatelessWidget {
  const DocumentFavoriteButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      builder: (context, state) {
        final isFavorite = state.views.any((v) => v.id == view.id);
        return _buildFavoriteButton(context, isFavorite);
      },
    );
  }

  Widget _buildFavoriteButton(BuildContext context, bool isFavorite) {
    return FlowyTooltip(
      message: isFavorite
          ? LocaleKeys.button_removeFromFavorites.tr()
          : LocaleKeys.button_addToFavorites.tr(),
      child: FlowyHover(
        child: GestureDetector(
          onTap: () =>
              context.read<FavoriteBloc>().add(FavoriteEvent.toggle(view)),
          child: _buildFavoriteIcon(context, isFavorite),
        ),
      ),
    );
  }

  Widget _buildFavoriteIcon(BuildContext context, bool isFavorite) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: FlowySvg(
        isFavorite ? FlowySvgs.favorite_s : FlowySvgs.unfavorite_s,
        size: const Size(18, 18),
        color: Theme.of(context).iconTheme.color,
      ),
    );
  }
}
