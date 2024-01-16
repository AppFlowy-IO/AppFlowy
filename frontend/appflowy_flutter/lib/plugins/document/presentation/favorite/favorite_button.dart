import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy/plugins/document/presentation/favorite/favorite_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentFavoriteButton extends StatelessWidget {
  const DocumentFavoriteButton({
    super.key,
    required this.view,
  });

  final ViewPB view;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          FavoriteCubit(FavoriteService(), view.id, view.isFavorite),
      child: BlocBuilder<FavoriteCubit, bool>(
        builder: (context, isFavorite) {
          return FlowyTooltip(
            message: isFavorite
                ? LocaleKeys.button_removeFromFavorites.tr()
                : LocaleKeys.button_addToFavorites.tr(),
            child: FlowyHover(
              child: GestureDetector(
                onTap: () => context.read<FavoriteCubit>().toggleFavorite(),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FlowySvg(
                    isFavorite ? FlowySvgs.favorite_s : FlowySvgs.unfavorite_s,
                    size: const Size(18, 18),
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
