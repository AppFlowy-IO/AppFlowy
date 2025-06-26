import 'package:appflowy/features/mension_person/data/cache/person_list_cache.dart';
import 'package:appflowy/features/mension_person/data/repositories/mock_mention_repository.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/hover_menu.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/mobile/mobile_person_profile_card.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person/person_profile_card.dart';
import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class MentionPersonBlock extends StatefulWidget {
  const MentionPersonBlock({
    super.key,
    required this.editorState,
    required this.personId,
    required this.pageId,
    required this.node,
    required this.textStyle,
    required this.index,
  });

  final EditorState editorState;
  final String personId;
  final String pageId;
  final Node node;
  final TextStyle? textStyle;

  // Used to update the block
  final int index;

  @override
  State<MentionPersonBlock> createState() => _MentionPersonBlockState();
}

class _MentionPersonBlockState extends State<MentionPersonBlock> {
  final key = GlobalKey();
  Size triggerSize = Size.zero;
  double positionY = 0;
  bool showAtBottom = false;
  RenderBox? get box => key.currentContext?.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();
    checkForPositionAndSize();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceId = context
            .read<UserWorkspaceBloc?>()
            ?.state
            .currentWorkspace
            ?.workspaceId ??
        '';
    return BlocProvider(
      create: (context) => PersonBloc(
        documentId: widget.pageId,
        personId: widget.personId,
        workspaceId: workspaceId,
        repository: MockMentionRepository(),
        personListCache: getIt<PersonListCache>(),
      )..add(PersonEvent.initial()),
      child: BlocListener<PersonBloc, PersonState>(
        listenWhen: (previous, current) =>
            previous.getPersonFailedMesssage != current.getPersonFailedMesssage,
        listener: (context, state) {
          if (state.getPersonFailedMesssage.isNotEmpty) {
            showToastNotification(
              message: state.getPersonFailedMesssage,
              type: ToastificationType.error,
            );
          }
        },
        child: BlocBuilder<PersonBloc, PersonState>(
          key: key,
          builder: (context, state) {
            if (state.person.isEmpty) return const SizedBox.shrink();
            final bloc = context.read<PersonBloc>();
            return HoverMenu(
              key: ValueKey(
                showAtBottom.hashCode &
                    positionY.hashCode &
                    triggerSize.hashCode,
              ),
              enable: UniversalPlatform.isDesktop,
              menuConstraints: BoxConstraints(
                maxHeight: 372,
                maxWidth: 280,
                minWidth: 280,
              ),
              triggerSize: triggerSize,
              direction: showAtBottom
                  ? PopoverDirection.bottomWithLeftAligned
                  : PopoverDirection.topWithLeftAligned,
              offset: Offset(
                0,
                showAtBottom ? -triggerSize.height : triggerSize.height,
              ),
              menuBuilder: (context, onEnter, onExit) => BlocProvider.value(
                value: bloc,
                child: BlocBuilder<PersonBloc, PersonState>(
                  builder: (context, state) => PersonProfileCard(
                    triggerSize: triggerSize,
                    showAtBottom: showAtBottom,
                    onEnter: onEnter,
                    onExit: onExit,
                  ),
                ),
              ),
              child: buildPerson(context),
            );
          },
        ),
      ),
    );
  }

  Widget buildPerson(BuildContext context) {
    final bloc = context.read<PersonBloc>(), state = bloc.state;
    final person = state.person;
    if (person.isEmpty) return const SizedBox.shrink();
    final theme = AppFlowyTheme.of(context);
    final color = state.access
        ? theme.textColorScheme.secondary
        : theme.textColorScheme.tertiary;
    final style = widget.textStyle?.copyWith(
          color: color,
          leadingDistribution: TextLeadingDistribution.even,
        ) ??
        theme.textStyle.body.standard(color: color);
    final richText = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '@',
              style: style.copyWith(
                color: theme.textColorScheme.tertiary,
              ),
            ),
            TextSpan(text: person.name, style: style),
          ],
        ),
      ),
    );
    return UniversalPlatform.isMobile
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showMobileBottomSheet(
                context,
                dragHandleBuilder: (_) => const DragHandleV2(),
                showDragHandle: true,
                showDivider: false,
                showHeader: true,
                showCloseButton: true,
                title: LocaleKeys.document_mentionMenu_profileCard.tr(),
                backgroundColor: theme.surfaceColorScheme.primary,
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: MobilePersonProfileCard(),
                ),
              );
            },
            child: richText,
          )
        : richText;
  }

  void checkForPositionAndSize() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = box;
      if (renderBox is RenderBox) {
        final position = renderBox.localToGlobal(Offset.zero);
        if (mounted) {
          setState(() {
            triggerSize = renderBox.size;
            positionY = position.dy;
          });
        }
        if (positionY < 300) {
          changeDirection(true);
        } else {
          changeDirection(false);
        }
      }
      checkForPositionAndSize();
    });
  }

  void changeDirection(bool bottom) {
    if (showAtBottom == bottom) return;
    if (mounted) {
      setState(() {
        showAtBottom = bottom;
      });
    }
  }
}
