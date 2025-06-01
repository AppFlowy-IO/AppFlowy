import 'package:appflowy/features/mension_person/data/repositories/mock_person_repository.dart';
import 'package:appflowy/features/mension_person/logic/person_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MentionPersonBlock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PersonBloc(
        documentId: pageId,
        personId: personId,
        repository: MockPersonRepository(),
      )..add(PersonEvent.initial()),
      child: BlocBuilder<PersonBloc, PersonState>(
        builder: (context, state) {
          final person = state.person;
          if (person == null) return const SizedBox.shrink();
          final theme = AppFlowyTheme.of(context);
          final color = state.access
              ? theme.textColorScheme.secondary
              : theme.textColorScheme.tertiary;
          final style = textStyle?.copyWith(
                color: color,
                leadingDistribution: TextLeadingDistribution.even,
              ) ??
              theme.textStyle.body.standard(color: color);
          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '@',
                  style: style.copyWith(color: theme.textColorScheme.tertiary),
                ),
                TextSpan(text: person.name, style: style),
              ],
            ),
          );
        },
      ),
    );
  }
}
