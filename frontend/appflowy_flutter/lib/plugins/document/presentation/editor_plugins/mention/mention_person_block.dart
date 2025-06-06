import 'package:appflowy/features/mension_person/data/repositories/mock_person_repository.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/hover_menu.dart';
import 'package:appflowy/features/mension_person/presentation/widgets/person_card_profile.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    checkForPositionAndSize();
  }

  void checkForPositionAndSize() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = key.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        final position = renderBox.localToGlobal(Offset.zero);
        setState(() {
          triggerSize = renderBox.size;
          positionY = position.dy;
        });
      }
      checkForPositionAndSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonBloc(
        documentId: widget.pageId,
        personId: widget.personId,
        repository: MockPersonRepository(),
      )..add(PersonEvent.initial()),
      child: BlocBuilder<PersonBloc, PersonState>(
        key: key,
        builder: (context, state) {
          final bloc = context.read<PersonBloc>();
          final person = state.person;
          if (person == null) return const SizedBox.shrink();
          final theme = AppFlowyTheme.of(context);
          final color = state.access
              ? theme.textColorScheme.secondary
              : theme.textColorScheme.tertiary;
          final style = widget.textStyle?.copyWith(
                color: color,
                leadingDistribution: TextLeadingDistribution.even,
              ) ??
              theme.textStyle.body.standard(color: color);
          return HoverMenu(
            key: ValueKey(positionY.hashCode & triggerSize.hashCode),
            menuConstraints: BoxConstraints(
              maxHeight: 372,
              maxWidth: 280,
              minWidth: 280,
            ),
            triggerSize: triggerSize,
            menuBuilder: (context) => BlocProvider.value(
              value: bloc,
              child: BlocBuilder<PersonBloc, PersonState>(
                builder: (context, state) =>
                    PersonCardProfile(triggerSize: triggerSize),
              ),
            ),
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
        },
      ),
    );
  }
}
