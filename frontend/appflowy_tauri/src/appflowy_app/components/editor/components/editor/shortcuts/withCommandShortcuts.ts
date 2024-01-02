import { ReactEditor } from 'slate-react';
import { Editor, Range } from 'slate';
import { CustomEditor } from '$app/components/editor/command';

export enum EditorCommand {
  Mention = '@',
  SlashCommand = '/',
}

// pop mention panel when @ is typed
// pop slash command panel when / is typed
const commands = [EditorCommand.Mention, EditorCommand.SlashCommand] as string[];

export const commandPanelClsSelector: Record<string, string> = {
  [EditorCommand.Mention]: '.mention-panel',
  [EditorCommand.SlashCommand]: '.slash-command-panel',
};

export const commandPanelShowProperty = 'is-show';

export function withCommandShortcuts(editor: ReactEditor) {
  const { insertText, deleteBackward } = editor;

  editor.insertText = (text) => {
    if (CustomEditor.isCodeBlock(editor) || CustomEditor.selectionIncludeRoot(editor)) {
      insertText(text);
      return;
    }

    const { selection } = editor;

    const endOfPanelChar = commands.find((char) => {
      return text.endsWith(char);
    });

    if (endOfPanelChar !== undefined && selection && Range.isCollapsed(selection)) {
      const block = CustomEditor.getBlock(editor);
      const path = block ? block[1] : [];
      const { anchor } = selection;
      const beforeText = Editor.string(editor, { anchor, focus: Editor.start(editor, path) }) + text.slice(0, -1);
      // show the panel when insert char at after space or at start of element
      const showPanel = !beforeText || beforeText.endsWith(' ');

      if (showPanel) {
        const slateDom = ReactEditor.toDOMNode(editor, editor);

        if (commands.includes(endOfPanelChar)) {
          const selector = commandPanelClsSelector[endOfPanelChar] || '';

          slateDom.parentElement?.querySelector(selector)?.classList.add(commandPanelShowProperty);
        }
      }
    }

    insertText(text);
  };

  editor.deleteBackward = (...args) => {
    if (CustomEditor.isCodeBlock(editor)) {
      deleteBackward(...args);
      return;
    }

    const { selection } = editor;

    if (selection && Range.isCollapsed(selection)) {
      const { anchor } = selection;
      const block = CustomEditor.getBlock(editor);
      const path = block ? block[1] : [];
      const beforeText = Editor.string(editor, { anchor, focus: Editor.start(editor, path) });

      // if delete backward at start of panel char, and then it will be deleted, so we should close the panel if it is open
      if (commands.includes(beforeText)) {
        const slateDom = ReactEditor.toDOMNode(editor, editor);

        const selector = commandPanelClsSelector[beforeText] || '';

        slateDom.parentElement?.querySelector(selector)?.classList.remove(commandPanelShowProperty);
      }

      // if delete backward at start of paragraph, and then it will be deleted, so we should close the panel if it is open
      if (CustomEditor.focusAtStartOfBlock(editor)) {
        const slateDom = ReactEditor.toDOMNode(editor, editor);

        commands.forEach((char) => {
          const selector = commandPanelClsSelector[char] || '';

          slateDom.parentElement?.querySelector(selector)?.classList.remove(commandPanelShowProperty);
        });
      }
    }

    deleteBackward(...args);
  };

  return editor;
}
