import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:time/time.dart';
import 'package:universal_platform/universal_platform.dart';

class ChatWelcomePage extends StatelessWidget {
  const ChatWelcomePage({
    required this.userProfile,
    required this.onSelectedQuestion,
    super.key,
  });

  final void Function(String) onSelectedQuestion;
  final UserProfilePB userProfile;

  static final List<String> desktopItems = [
    LocaleKeys.chat_question1.tr(),
    LocaleKeys.chat_question2.tr(),
    LocaleKeys.chat_question3.tr(),
    LocaleKeys.chat_question4.tr(),
  ];

  static final List<List<String>> mobileItems = [
    [
      LocaleKeys.chat_question1.tr(),
      LocaleKeys.chat_question2.tr(),
    ],
    [
      LocaleKeys.chat_question3.tr(),
      LocaleKeys.chat_question4.tr(),
    ],
    [
      LocaleKeys.chat_question5.tr(),
      LocaleKeys.chat_question6.tr(),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FlowySvg(
          FlowySvgs.flowy_logo_xl,
          size: Size.square(32),
          blendMode: null,
        ),
        const VSpace(16),
        FlowyText(
          fontSize: 15,
          LocaleKeys.chat_questionDetail.tr(args: [userProfile.name]),
        ),
        UniversalPlatform.isDesktop ? const VSpace(32 - 16) : const VSpace(24),
        ...UniversalPlatform.isDesktop
            ? buildDesktopSampleQuestions(context)
            : buildMobileSampleQuestions(context),
      ],
    );
  }

  Iterable<Widget> buildDesktopSampleQuestions(BuildContext context) {
    return desktopItems.map(
      (question) => Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: WelcomeSampleQuestion(
          question: question,
          onSelected: onSelectedQuestion,
        ),
      ),
    );
  }

  Iterable<Widget> buildMobileSampleQuestions(BuildContext context) {
    return [
      _AutoScrollingSampleQuestions(
        key: const ValueKey('inf_scroll_1'),
        onSelected: onSelectedQuestion,
        questions: mobileItems[0],
        offset: 60.0,
      ),
      const VSpace(8),
      _AutoScrollingSampleQuestions(
        key: const ValueKey('inf_scroll_2'),
        onSelected: onSelectedQuestion,
        questions: mobileItems[1],
        offset: -50.0,
        reverse: true,
      ),
      const VSpace(8),
      _AutoScrollingSampleQuestions(
        key: const ValueKey('inf_scroll_3'),
        onSelected: onSelectedQuestion,
        questions: mobileItems[2],
        offset: 120.0,
      ),
    ];
  }
}

class WelcomeSampleQuestion extends StatelessWidget {
  const WelcomeSampleQuestion({
    required this.question,
    required this.onSelected,
    super.key,
  });

  final void Function(String) onSelected;
  final String question;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -2,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withOpacity(0.02),
          ),
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withOpacity(0.02),
          ),
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 2,
            color: isLightMode
                ? const Color(0x051F2329)
                : Theme.of(context).shadowColor.withOpacity(0.02),
          ),
        ],
      ),
      child: TextButton(
        onPressed: () => onSelected(question),
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 16,
              vertical: UniversalPlatform.isDesktop ? 8 : 0,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((state) {
            if (state.contains(WidgetState.hovered)) {
              return isLightMode
                  ? const Color(0xFFF9FAFD)
                  : AFThemeExtension.of(context).lightGreyHover;
            }
            return Theme.of(context).colorScheme.surface;
          }),
          overlayColor: WidgetStateColor.transparent,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
        child: FlowyText(
          question,
          fontSize: 14,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _AutoScrollingSampleQuestions extends StatefulWidget {
  const _AutoScrollingSampleQuestions({
    super.key,
    required this.questions,
    this.offset = 0.0,
    this.reverse = false,
    required this.onSelected,
  });

  final List<String> questions;
  final void Function(String) onSelected;
  final double offset;
  final bool reverse;

  @override
  State<_AutoScrollingSampleQuestions> createState() =>
      _AutoScrollingSampleQuestionsState();
}

class _AutoScrollingSampleQuestionsState
    extends State<_AutoScrollingSampleQuestions> {
  final restartAutoScrollDebounce = Debounce(duration: 3.seconds);
  late final ScrollController scrollController;

  bool userIntervened = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(
      onAttach: onAttach,
      initialScrollOffset: widget.offset,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          return false;
        }
        if (notification is ScrollEndNotification && !userIntervened) {
          startScroll();
        } else if (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle) {
          scheduleRestart();
        }
        return false;
      },
      child: SizedBox(
        height: 36,
        child: Stack(
          children: [
            InfiniteScrollView(
              centerKey: UniqueKey(),
              scrollController: scrollController,
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                return WelcomeSampleQuestion(
                  question: widget.questions[index],
                  onSelected: widget.onSelected,
                );
              },
              separatorBuilder: (context, index) => const HSpace(8),
            ),
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                userIntervened = true;
                scrollController.jumpTo(scrollController.offset);
              },
            ),
          ],
        ),
      ),
    );
  }

  void onAttach(ScrollPosition position) {
    startScroll();
  }

  void startScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final delta = widget.reverse ? -250 : 250;
      scrollController.animateTo(
        scrollController.offset + delta,
        duration: 20.seconds,
        curve: Curves.linear,
      );
    });
  }

  void scheduleRestart() {
    restartAutoScrollDebounce.call(() {
      userIntervened = false;
      startScroll();
    });
  }
}

class InfiniteScrollView extends StatelessWidget {
  const InfiniteScrollView({
    super.key,
    required this.itemCount,
    required this.centerKey,
    required this.itemBuilder,
    required this.separatorBuilder,
    this.scrollController,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index) separatorBuilder;
  final Key centerKey;

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      scrollDirection: Axis.horizontal,
      controller: scrollController,
      center: centerKey,
      anchor: 0.5,
      slivers: [
        _buildList(isForward: false),
        SliverToBoxAdapter(
          child: separatorBuilder.call(context, 0),
        ),
        SliverToBoxAdapter(
          key: centerKey,
          child: itemBuilder.call(context, 0),
        ),
        SliverToBoxAdapter(
          child: separatorBuilder.call(context, 0),
        ),
        _buildList(isForward: true),
      ],
    );
  }

  Widget _buildList({required bool isForward}) {
    return SliverList.separated(
      itemBuilder: (context, index) {
        index = (index + 1) % itemCount;
        return itemBuilder(context, index);
      },
      separatorBuilder: (context, index) {
        index = (index + 1) % itemCount;
        return separatorBuilder(context, index);
      },
    );
  }
}
