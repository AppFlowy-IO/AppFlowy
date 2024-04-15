import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PageStyleBottomSheet extends StatelessWidget {
  const PageStyleBottomSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowyText(
            LocaleKeys.pageStyle_layout.tr(),
          ),
          const VSpace(8.0),
          const _PageStyleLayout(),
        ],
      ),
    );
  }
}

class _PageStyleLayout extends StatefulWidget {
  const _PageStyleLayout();

  @override
  State<_PageStyleLayout> createState() => _PageStyleLayoutState();
}

class _PageStyleLayoutState extends State<_PageStyleLayout> {
  PageStyleFontLayout selectedFont = PageStyleFontLayout.small;
  PageStyleLineHeightLayout selectedLineHeight =
      PageStyleLineHeightLayout.normal;

  @override
  Widget build(BuildContext context) {
    final themeMode = Theme.of(context).brightness;
    final backgroundColor = themeMode == Brightness.light
        ? const Color(0xFFF5F5F8)
        : const Color(0xFF303030);
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return Stack(
          children: [
            Row(
              children: [
                // small font
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildFontButton(PageStyleFontLayout.small, state),
                        // normal font
                        _buildFontButton(PageStyleFontLayout.normal, state),
                        // large font
                        _buildFontButton(PageStyleFontLayout.large, state),
                      ],
                    ),
                  ),
                ),
                const HSpace(14),
                // small line height
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                        right: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildLinHeightButton(
                          PageStyleLineHeightLayout.small,
                          state,
                        ),
                        // normal line height
                        _buildLinHeightButton(
                          PageStyleLineHeightLayout.normal,
                          state,
                        ),
                        // large line height
                        _buildLinHeightButton(
                          PageStyleLineHeightLayout.large,
                          state,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFontButton(
    PageStyleFontLayout fontLayout,
    DocumentPageStyleState state,
  ) {
    final child = switch (fontLayout) {
      PageStyleFontLayout.small =>
        const FlowySvg(FlowySvgs.m_font_size_small_s),
      PageStyleFontLayout.normal =>
        const FlowySvg(FlowySvgs.m_font_size_normal_s),
      PageStyleFontLayout.large =>
        const FlowySvg(FlowySvgs.m_font_size_large_s),
    };
    final showLeftCorner = fontLayout == PageStyleFontLayout.small;
    final showRightCorner = fontLayout == PageStyleFontLayout.large;
    return _buildButton(
      child,
      showLeftCorner,
      showRightCorner,
      state.fontLayout == fontLayout,
      () => context.read<DocumentPageStyleBloc>().add(
            DocumentPageStyleEvent.updateFont(fontLayout),
          ),
    );
  }

  Widget _buildLinHeightButton(
    PageStyleLineHeightLayout lineHeightLayout,
    DocumentPageStyleState state,
  ) {
    final child = switch (lineHeightLayout) {
      PageStyleLineHeightLayout.small =>
        const FlowySvg(FlowySvgs.m_layout_small_s),
      PageStyleLineHeightLayout.normal =>
        const FlowySvg(FlowySvgs.m_layout_normal_s),
      PageStyleLineHeightLayout.large =>
        const FlowySvg(FlowySvgs.m_layout_large_s),
    };
    final showLeftCorner = lineHeightLayout == PageStyleLineHeightLayout.small;
    final showRightCorner = lineHeightLayout == PageStyleLineHeightLayout.large;
    return _buildButton(
      child,
      showLeftCorner,
      showRightCorner,
      state.lineHeightLayout == lineHeightLayout,
      () => context.read<DocumentPageStyleBloc>().add(
            DocumentPageStyleEvent.updateLineHeight(lineHeightLayout),
          ),
    );
  }

  Widget _buildButton(
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
          height: 52,
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
