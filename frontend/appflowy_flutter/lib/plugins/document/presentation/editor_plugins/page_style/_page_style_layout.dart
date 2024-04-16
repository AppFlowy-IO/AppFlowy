import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy/shared/feedback_gesture_detector.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PageStyleLayout extends StatelessWidget {
  const PageStyleLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = context.pageStyleBackgroundColor;
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                _buildOptionGroup(
                  backgroundColor,
                  [
                    PageStyleFontLayout.small,
                    PageStyleFontLayout.normal,
                    PageStyleFontLayout.large,
                  ],
                  state.fontLayout,
                  (option) => context
                      .read<DocumentPageStyleBloc>()
                      .add(DocumentPageStyleEvent.updateFont(option)),
                ),
                const HSpace(14),
                _buildOptionGroup(
                  backgroundColor,
                  [
                    PageStyleLineHeightLayout.small,
                    PageStyleLineHeightLayout.normal,
                    PageStyleLineHeightLayout.large,
                  ],
                  state.lineHeightLayout,
                  (option) => context
                      .read<DocumentPageStyleBloc>()
                      .add(DocumentPageStyleEvent.updateLineHeight(option)),
                ),
              ],
            ),
            // the font here will conflict with the font in the editor.
            // disable the font button for now.
            /*
            const VSpace(12.0),
            _buildFontButton(backgroundColor, state, () {}),
            */
          ],
        );
      },
    );
  }

  Widget _buildOptionGroup<T>(
    Color backgroundColor,
    List<T> options,
    dynamic selectedOption,
    void Function(T option) onTap,
  ) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(12),
            right: Radius.circular(12),
          ),
        ),
        child: Row(
          children: options.map((option) {
            final child = _buildSvg(option);
            final showLeftCorner = option == options.first;
            final showRightCorner = option == options.last;
            return _buildOptionButton(
              child,
              showLeftCorner,
              showRightCorner,
              selectedOption == option,
              () => onTap(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSvg(dynamic option) {
    if (option is PageStyleFontLayout) {
      return switch (option) {
        PageStyleFontLayout.small =>
          const FlowySvg(FlowySvgs.m_font_size_small_s),
        PageStyleFontLayout.normal =>
          const FlowySvg(FlowySvgs.m_font_size_normal_s),
        PageStyleFontLayout.large =>
          const FlowySvg(FlowySvgs.m_font_size_large_s),
      };
    } else if (option is PageStyleLineHeightLayout) {
      return switch (option) {
        PageStyleLineHeightLayout.small =>
          const FlowySvg(FlowySvgs.m_layout_small_s),
        PageStyleLineHeightLayout.normal =>
          const FlowySvg(FlowySvgs.m_layout_normal_s),
        PageStyleLineHeightLayout.large =>
          const FlowySvg(FlowySvgs.m_layout_large_s),
      };
    }
    throw ArgumentError('Invalid option type');
  }

  Widget _buildOptionButton(
    Widget child,
    bool showLeftCorner,
    bool showRightCorner,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: FeedbackGestureDetector(
        feedbackType: HapticFeedbackType.medium,
        onTap: onTap,
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

  // the font here will conflict with the font in the editor.
  // disable the font button for now.
  /*
  Widget _buildFontButton(
    Color backgroundColor,
    DocumentPageStyleState state,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            const HSpace(16.0),
            FlowyText(LocaleKeys.titleBar_font.tr()),
            const Spacer(),
            FlowyText(state.fontFamily ?? builtInFontFamily()),
            const HSpace(6.0),
            const FlowySvg(FlowySvgs.m_page_style_arrow_right_s),
            const HSpace(12.0),
          ],
        ),
      ),
    );
  }
  */
}
