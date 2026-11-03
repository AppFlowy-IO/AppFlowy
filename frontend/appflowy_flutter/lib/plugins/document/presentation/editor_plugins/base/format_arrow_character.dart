import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

const _greater = '>';
const _dash = '-';
const _equals = '=';
const _equalGreater = '⇒';
const _dashGreater = '→';

const _hyphen = '-';
const _emDash = '—'; // This is an em dash — not a single dash - !!

/// format '=' + '>' into an ⇒
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CharacterShortcutEvent customFormatGreaterEqual = CharacterShortcutEvent(
  key: 'format = + > into ⇒',
  character: _greater,
  handler: (editorState) async => _handleDoubleCharacterReplacement(
    editorState: editorState,
    character: _greater,
    replacement: _equalGreater,
    prefixCharacter: _equals,
  ),
);

/// format '-' + '>' into ⇒
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CharacterShortcutEvent customFormatDashGreater = CharacterShortcutEvent(
  key: 'format - + > into ->',
  character: _greater,
  handler: (editorState) async => _handleDoubleCharacterReplacement(
    editorState: editorState,
    character: _greater,
    replacement: _dashGreater,
    prefixCharacter: _dash,
  ),
);

/// format two hyphens into an em dash
///
/// - support
///   - desktop
///   - mobile
///   - web
///
final CharacterShortcutEvent customFormatDoubleHyphenEmDash =
    CharacterShortcutEvent(
  key: 'format double hyphen into an em dash',
  character: _hyphen,
  handler: (editorState) async => _handleDoubleCharacterReplacement(
    editorState: editorState,
    character: _hyphen,
    replacement: _emDash,
  ),
);

/// format (c) into ©
final CharacterShortcutEvent customFormatCopyright = CharacterShortcutEvent(
  key: 'format (c) into ©',
  character: ')',
  handler: (editorState) async => _handleTripleCharacterReplacement(
    editorState: editorState,
    triggerCharacter: ')',
    expectedPrefix: '(c',
    replacement: '©',
  ),
);

/// format (r) into ®
final CharacterShortcutEvent customFormatRegistered = CharacterShortcutEvent(
  key: 'format (r) into ®',
  character: ')',
  handler: (editorState) async => _handleTripleCharacterReplacement(
    editorState: editorState,
    triggerCharacter: ')',
    expectedPrefix: '(r',
    replacement: '®',
  ),
);

/// format (p) into ℗
final CharacterShortcutEvent customFormatSoundRecording = CharacterShortcutEvent(
  key: 'format (p) into ℗',
  character: ')',
  handler: (editorState) async => _handleTripleCharacterReplacement(
    editorState: editorState,
    triggerCharacter: ')',
    expectedPrefix: '(p',
    replacement: '℗',
  ),
);

/// format ^tm into ™
final CharacterShortcutEvent customFormatTrademark = CharacterShortcutEvent(
  key: 'format ^tm into ™',
  character: 'm',
  handler: (editorState) async => _handleTripleCharacterReplacement(
    editorState: editorState,
    triggerCharacter: 'm',
    expectedPrefix: '^t',
    replacement: '™',
  ),
);

/// If [prefixCharacter] is null or empty, [character] is used
Future<bool> _handleDoubleCharacterReplacement({
  required EditorState editorState,
  required String character,
  required String replacement,
  String? prefixCharacter,
}) async {
  assert(character.length == 1);

  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null ||
      delta == null ||
      delta.isEmpty ||
      node.type == CodeBlockKeys.type) {
    return false;
  }

  if (selection.end.offset > 0) {
    final plain = delta.toPlainText();

    final expectedPrevious =
        prefixCharacter?.isEmpty ?? true ? character : prefixCharacter;

    final previousCharacter = plain[selection.end.offset - 1];
    if (previousCharacter != expectedPrevious) {
      return false;
    }

    // insert the greater character first and convert it to the replacement character to support undo
    final insert = editorState.transaction
      ..insertText(
        node,
        selection.end.offset,
        character,
      );

    await editorState.apply(
      insert,
      skipHistoryDebounce: true,
    );

    final afterSelection = editorState.selection;
    if (afterSelection == null) {
      return false;
    }

    final replace = editorState.transaction
      ..replaceText(
        node,
        afterSelection.end.offset - 2,
        2,
        replacement,
      );

    await editorState.apply(replace);

    return true;
  }

  return false;
}

Future<bool> _handleTripleCharacterReplacement({
  required EditorState editorState,
  required String triggerCharacter,
  required String expectedPrefix,
  required String replacement,
}) async {
  final selection = editorState.selection;
  if (selection == null) return false;

  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  final node = editorState.getNodeAtPath(selection.end.path);
  final delta = node?.delta;
  if (node == null || delta == null || delta.isEmpty || node.type == CodeBlockKeys.type) {
    return false;
  }

  final offset = selection.end.offset;
  if (offset >= expectedPrefix.length) {
    final plain = delta.toPlainText();
    final actualPrefix = plain.substring(offset - expectedPrefix.length, offset);
    if (actualPrefix.toLowerCase() != expectedPrefix.toLowerCase()) {
      return false;
    }

    final insert = editorState.transaction
      ..insertText(node, offset, triggerCharacter);

    await editorState.apply(insert, skipHistoryDebounce: true);

    final afterSelection = editorState.selection;
    if (afterSelection == null) return false;

    final replace = editorState.transaction
      ..replaceText(
        node,
        afterSelection.end.offset - (expectedPrefix.length + 1),
        expectedPrefix.length + 1,
        replacement,
      );

    await editorState.apply(replace);
    return true;
  }

  return false;
}
