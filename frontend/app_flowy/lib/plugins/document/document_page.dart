import 'package:app_flowy/plugins/document/presentation/plugins/local_image_node_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../startup/startup.dart';
import 'application/doc_bloc.dart';
import 'editor_styles.dart';
import 'presentation/banner.dart';
import 'package:get_it/get_it.dart';
import '../../workspace/application/settings/settings_location_cubit.dart';
import 'dart:io';

final directory = getIt<SettingsLocationCubit>()
    .fetchLocation()
    .then((value) => Directory(value));

class DocumentPage extends StatefulWidget {
  final VoidCallback onDeleted;
  final ViewPB view;

  DocumentPage({
    required this.view,
    required this.onDeleted,
    Key? key,
  }) : super(key: ValueKey(view.id));

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late DocumentBloc documentBloc;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    // The appflowy editor use Intl as localization, set the default language as fallback.
    Intl.defaultLocale = 'en_US';
    documentBloc = getIt<DocumentBloc>(param1: super.widget.view)
      ..add(const DocumentEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocumentBloc>.value(value: documentBloc),
      ],
      child:
          BlocBuilder<DocumentBloc, DocumentState>(builder: (context, state) {
        return state.loadingState.map(
          loading: (_) => SizedBox.expand(
            child: Container(color: Colors.transparent),
          ),
          finish: (result) => result.successOrFail.fold(
            (_) {
              if (state.forceClose) {
                widget.onDeleted();
                return const SizedBox();
              } else {
                return _renderDocument(context, state);
              }
            },
            (err) => FlowyErrorPage(err.toString()),
          ),
        );
      }),
    );
  }

  @override
  Future<void> dispose() async {
    documentBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _renderDocument(BuildContext context, DocumentState state) {
    return Column(
      children: [
        if (state.isDeleted) _renderBanner(context),
        // AppFlowy Editor
        _renderAppFlowyEditor(
          context.read<DocumentBloc>().editorState,
        ),
      ],
    );
  }

  Widget _renderBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () =>
          context.read<DocumentBloc>().add(const DocumentEvent.restorePage()),
      onDelete: () => context
          .read<DocumentBloc>()
          .add(const DocumentEvent.deletePermanently()),
    );
  }

  Widget _renderAppFlowyEditor(EditorState editorState) {
    final theme = Theme.of(context);
    final editorMaxWidth = MediaQuery.of(context).size.width * 0.6;
    final editor = AppFlowyEditor(
      editorState: editorState,
      autoFocus: editorState.document.isEmpty,
      customBuilders: {
        // Divider
        kDividerType: DividerWidgetBuilder(),
        // Math Equation
        kMathEquationType: MathEquationNodeWidgetBuidler(),
        // Code Block
        kCodeBlockType: CodeBlockNodeWidgetBuilder(),
        kLocalImage: LocalImageNodeWidgetBuilder(directory)
      },
      shortcutEvents: [
        // Divider
        insertDividerEvent,
        // Code Block
        enterInCodeBlock,
        ignoreKeysInCodeBlock,
        pasteInCodeBlock,
      ],
      selectionMenuItems: [
        // Divider
        dividerMenuItem,
        // Math Equation
        mathEquationMenuItem,
        // Code Block
        codeBlockMenuItem,
        // Emoji
        emojiMenuItem,
      ],
      themeData: theme.copyWith(extensions: [
        ...theme.extensions.values,
        customEditorTheme(context),
        ...customPluginTheme(context),
      ]),
    );
    return Expanded(
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: editorMaxWidth,
          ),
          child: editor,
        ),
      ),
    );
  }
}
