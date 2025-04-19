import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/home/tab/mobile_space_tab.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FloatingAIEntry extends StatelessWidget {
  const FloatingAIEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedGestureDetector(
      scaleFactor: 0.99,
      onTapUp: () => mobileCreateNewAIChatNotifier.value =
          mobileCreateNewAIChatNotifier.value + 1,
      child: Hero(
        tag: "ai_chat_prompt",
        child: DecoratedBox(
          decoration: _buildShadowDecoration(context),
          child: Container(
            decoration: _buildWrapperDecoration(context),
            height: 48,
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: _buildHintText(context),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildShadowDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 4),
          color: Colors.black.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  BoxDecoration _buildWrapperDecoration(BuildContext context) {
    final outlineColor = Theme.of(context).colorScheme.outline;
    final borderColor = Theme.of(context).isLightMode
        ? outlineColor.withValues(alpha: 0.7)
        : outlineColor.withValues(alpha: 0.3);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      color: Theme.of(context).colorScheme.surface,
      border: Border.fromBorderSide(
        BorderSide(
          color: borderColor,
        ),
      ),
    );
  }

  Widget _buildHintText(BuildContext context) {
    return Row(
      children: [
        FlowySvg(
          FlowySvgs.toolbar_item_ai_s,
          size: const Size.square(16.0),
          color: Theme.of(context).hintColor,
          opacity: 0.7,
        ),
        const HSpace(8),
        FlowyText(
          LocaleKeys.chat_inputMessageHint.tr(),
          color: Theme.of(context).hintColor,
        ),
      ],
    );
  }
}

class FloatingAIEntryV2 extends StatelessWidget {
  const FloatingAIEntryV2({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return GestureDetector(
      onTap: () {
        mobileCreateNewAIChatNotifier.value =
            mobileCreateNewAIChatNotifier.value + 1;
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.surfaceColorScheme.primary,
          boxShadow: [theme.shadow.small],
          border: Border.all(color: Color(0xFFF1E0FF)),
        ),
        child: Center(
          child: FlowySvg(
            FlowySvgs.m_home_ai_chat_icon_m,
            blendMode: null,
            size: Size(24, 24),
          ),
        ),
      ),
    );
  }
}
