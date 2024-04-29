import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_util.dart';
import 'package:appflowy/shared/feedback_gesture_detector.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const kPageStyleLayoutHeight = 52.0;

class PageStyleLayout extends StatelessWidget {
  const PageStyleLayout({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return Column(
          children: [
            Row(
              children: [
                _OptionGroup<PageStyleFontLayout>(
                  options: const [
                    PageStyleFontLayout.small,
                    PageStyleFontLayout.normal,
                    PageStyleFontLayout.large,
                  ],
                  selectedOption: state.fontLayout,
                  onTap: (option) => context
                      .read<DocumentPageStyleBloc>()
                      .add(DocumentPageStyleEvent.updateFont(option)),
                ),
                const HSpace(14),
                _OptionGroup<PageStyleLineHeightLayout>(
                  options: const [
                    PageStyleLineHeightLayout.small,
                    PageStyleLineHeightLayout.normal,
                    PageStyleLineHeightLayout.large,
                  ],
                  selectedOption: state.lineHeightLayout,
                  onTap: (option) => context
                      .read<DocumentPageStyleBloc>()
                      .add(DocumentPageStyleEvent.updateLineHeight(option)),
                ),
              ],
            ),
            const VSpace(12.0),
            const _FontButton(),
          ],
        );
      },
    );
  }
}

class _OptionGroup<T> extends StatelessWidget {
  const _OptionGroup({
    required this.options,
    required this.selectedOption,
    required this.onTap,
  });

  final List<T> options;
  final T selectedOption;
  final void Function(T option) onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.pageStyleBackgroundColor,
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
          height: kPageStyleLayoutHeight,
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
}

class _FontButton extends StatelessWidget {
  const _FontButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () => _showFontSelector(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: kPageStyleLayoutHeight,
            decoration: BoxDecoration(
              color: context.pageStyleBackgroundColor,
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
      },
    );
  }

  void _showFontSelector(BuildContext context) {
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      showDoneButton: true,
      showHeader: true,
      title: LocaleKeys.titleBar_font.tr(),
      barrierColor: Colors.transparent,
      backgroundColor: Theme.of(context).colorScheme.background,
      isScrollControlled: true,
      enableDraggableScrollable: true,
      minChildSize: 0.6,
      initialChildSize: 0.61,
      scrollableWidgetBuilder: (_, controller) {
        return BlocProvider.value(
          value: context.read<DocumentPageStyleBloc>(),
          child: BlocBuilder<DocumentPageStyleBloc, DocumentPageStyleState>(
            builder: (context, state) {
              return Expanded(
                child: FontSelector(
                  scrollController: controller,
                  selectedFontFamilyName:
                      state.fontFamily ?? builtInFontFamily(),
                  onFontFamilySelected: (fontFamilyName) {
                    context.read<DocumentPageStyleBloc>().add(
                          DocumentPageStyleEvent.updateFontFamily(
                            fontFamilyName,
                          ),
                        );
                  },
                ),
              );
            },
          ),
        );
      },
      builder: (_) => const SizedBox.shrink(),
    );
  }
}
