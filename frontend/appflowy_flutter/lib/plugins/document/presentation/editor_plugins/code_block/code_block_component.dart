import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

class AppFlowyCodeBlockKeys {
  const AppFlowyCodeBlockKeys._();

  /// Whether long lines should wrap inside the code block.
  ///
  /// The value is a bool and defaults to false when absent or invalid.
  static const String wrapLines = 'wrap_lines';
}

extension AppFlowyCodeBlockNodeExtension on Node {
  bool get codeBlockWrapLines =>
      attributes[AppFlowyCodeBlockKeys.wrapLines] == true;
}

/// Adds AppFlowy-specific, per-node styling to the editor plugin's code block.
class AppFlowyCodeBlockComponentBuilder extends CodeBlockComponentBuilder {
  AppFlowyCodeBlockComponentBuilder({
    required CodeBlockStyle Function() styleBuilder,
    required super.configuration,
    required super.padding,
    required CodeBlockLanguagePickerBuilder languagePickerBuilder,
    required CodeBlockCopyBuilder copyButtonBuilder,
  }) : super(
          styleBuilder: styleBuilder,
          languagePickerBuilder: languagePickerBuilder,
          copyButtonBuilder: copyButtonBuilder,
        );

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    final wrapLines = node.codeBlockWrapLines;
    final baseStyle = styleBuilder?.call() ?? const CodeBlockStyle();

    return CodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      padding: padding,
      showActions: showActions(node),
      actionBuilder: (_, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
      actionWrapperBuilder: actionWrapperBuilder,
      style: CodeBlockStyle(
        textStyle: baseStyle.textStyle,
        backgroundColor: baseStyle.backgroundColor,
        foregroundColor: baseStyle.foregroundColor,
        showLineNumbers: wrapLines ? false : baseStyle.showLineNumbers,
        wrapLines: wrapLines,
      ),
      languagePickerBuilder: languagePickerBuilder,
      actions: actions,
      copyButtonBuilder: copyButtonBuilder,
      localizations: localizations,
    );
  }
}
