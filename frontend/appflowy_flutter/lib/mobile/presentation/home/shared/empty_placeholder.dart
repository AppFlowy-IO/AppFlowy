import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/shared/mobile_page_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class EmptySpacePlaceholder extends StatelessWidget {
  const EmptySpacePlaceholder({super.key, required this.type});

  final MobilePageCardType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FlowySvg(
            FlowySvgs.m_empty_page_xl,
          ),
          const VSpace(16.0),
          FlowyText.medium(
            _emptyPageText,
            fontSize: 18.0,
            textAlign: TextAlign.center,
          ),
          const VSpace(8.0),
          FlowyText.regular(
            _emptyPageSubText,
            fontSize: 17.0,
            maxLines: 10,
            textAlign: TextAlign.center,
            lineHeight: 1.3,
            color: Theme.of(context).hintColor,
          ),
          const VSpace(kBottomNavigationBarHeight + 36.0),
        ],
      ),
    );
  }

  String get _emptyPageText => switch (type) {
        MobilePageCardType.recent => LocaleKeys.sideBar_emptyRecent.tr(),
        MobilePageCardType.favorite => LocaleKeys.sideBar_emptyFavorite.tr(),
      };

  String get _emptyPageSubText => switch (type) {
        MobilePageCardType.recent =>
          LocaleKeys.sideBar_emptyRecentDescription.tr(),
        MobilePageCardType.favorite =>
          LocaleKeys.sideBar_emptyFavoriteDescription.tr(),
      };
}
