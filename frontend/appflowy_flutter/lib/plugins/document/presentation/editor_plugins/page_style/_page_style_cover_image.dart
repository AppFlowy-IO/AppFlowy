import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_cover_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PageStyleCoverImage extends StatelessWidget {
  const PageStyleCoverImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.pageStyleBackgroundColor;
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return Row(
          children: [
            _buildOptionGroup(
              context,
              backgroundColor,
              state,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionGroup(
    BuildContext context,
    Color backgroundColor,
    DocumentPageStyleState state,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(12),
            right: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            _buildOptionButton(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FlowySvg(
                    FlowySvgs.m_page_style_presets_m,
                    blendMode: null,
                  ),
                  const VSpace(2.0),
                  FlowyText(
                    LocaleKeys.pageStyle_presets.tr(),
                    fontSize: 12.0,
                  ),
                ],
              ),
              true,
              false,
              state.coverImage.isPresets,
              () {
                showMobileBottomSheet(
                  context,
                  showDragHandle: true,
                  showDivider: false,
                  showDoneButton: true,
                  showHeader: true,
                  showRemoveButton: true,
                  title: LocaleKeys.pageStyle_coverImage.tr(),
                  barrierColor: Colors.transparent,
                  backgroundColor: Theme.of(context).colorScheme.background,
                  builder: (_) {
                    return BlocProvider.value(
                      value: context.read<DocumentPageStyleBloc>(),
                      child: const PageCoverBottomSheet(),
                    );
                  },
                );
              },
            ),
            _buildOptionButton(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FlowySvg(FlowySvgs.m_page_style_photo_m),
                  const VSpace(2.0),
                  FlowyText(
                    LocaleKeys.pageStyle_photo.tr(),
                    fontSize: 12.0,
                  ),
                ],
              ),
              false,
              false,
              state.coverImage.isCustomImage,
              () {},
            ),
            _buildOptionButton(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FlowySvg(FlowySvgs.m_page_style_unsplash_m),
                  const VSpace(2.0),
                  FlowyText(
                    LocaleKeys.pageStyle_unsplash.tr(),
                    fontSize: 12.0,
                  ),
                ],
              ),
              false,
              true,
              state.coverImage.isUnsplashImage,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    Widget child,
    bool showLeftCorner,
    bool showRightCorner,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          height: 64,
          duration: Durations.medium1,
          decoration: selected
              ? ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(
                      width: 1.50,
                      color: Color(0xFF1AC3F2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
