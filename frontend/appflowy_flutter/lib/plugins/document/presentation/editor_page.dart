import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tuple/tuple.dart';

/// Wrapper for the appflowy editor.
class AppFlowyEditorPage extends StatefulWidget {
  const AppFlowyEditorPage({super.key});

  @override
  State<AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<AppFlowyEditorPage> {
  late final EditorState editorState =
      documentBloc.editorState ?? EditorState.empty();

  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autoFocusParameters = _computeAutoFocusParameters();

    /*
    final editor = AppFlowyEditor.standard(
      editorState: editorState,
      editable: true,
      // setup the auto focus parameters
      autoFocus: autoFocusParameters.item1,
      focusedSelection: autoFocusParameters.item2,
      // setup the theme
      editorStyle: _desktopEditorStyle(),
    );
    */
    final slashMenuItems = [
      boardMenuItem,
      gridMenuItem,
      calloutItem,
      dividerMenuItem,
    ];

    final editor = AppFlowyEditor.custom(
      editorState: editorState,
      editable: true,
      // setup the auto focus parameters
      autoFocus: autoFocusParameters.item1,
      focusedSelection: autoFocusParameters.item2,
      // setup the theme
      editorStyle: _desktopEditorStyle(),
      // custom the block builder
      blockComponentBuilders: {
        ...standardBlockComponentBuilderMap,
        BoardBlockKeys.type: const BoardBlockComponentBuilder(),
        GridBlockKeys.type: const GridBlockComponentBuilder(),
        CalloutBlockKeys.type: const CalloutBlockComponentBuilder(),
        DividerBlockKeys.type: const DividerBlockComponentBuilder(),
      },
      // default shortcuts
      characterShortcutEvents: [
        ...standardCharacterShortcutEvents
          ..removeWhere(
            (element) => element == slashCommand,
          ), // remove the default slash command.
        customSlashCommand(slashMenuItems),

        // divider
        insertDividerCommand,
      ],
      commandShortcutEvents: [
        ...standardCommandShortcutEvents,
      ],
    );

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
        ),
        child: editor,
      ),
    );
  }

  EditorStyle _desktopEditorStyle() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return EditorStyle.desktop(
      padding: const EdgeInsets.symmetric(horizontal: 100),
      backgroundColor: theme.colorScheme.surface,
      cursorColor: theme.colorScheme.primary,
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(
          fontFamily: 'poppins',
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
        ),
        bold: const TextStyle(
          fontFamily: 'poppins-Bold',
          fontWeight: FontWeight.w600,
        ),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface,
          ),
        ),
      ),
    );
  }

  Tuple2<bool, Selection?> _computeAutoFocusParameters() {
    if (editorState.document.isEmpty) {
      return Tuple2(true, Selection.collapse([0], 0));
    }
    final nodes = editorState.document.root.children
        .where((element) => element.delta != null);
    final isAllEmpty =
        nodes.isNotEmpty && nodes.every((element) => element.delta!.isEmpty);
    if (isAllEmpty) {
      return Tuple2(true, Selection.collapse(nodes.first.path, 0));
    }
    return const Tuple2(false, null);
  }
}
