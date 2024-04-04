import { Range, Element, Editor, NodeEntry, Path } from 'slate';
import { ReactEditor } from 'slate-react';
import {
  defaultTriggerChar,
  getRegex,
  MarkdownShortcuts,
  whatShortcutsMatch,
  whatShortcutTrigger,
} from '$app/components/editor/plugins/shortcuts/markdown';
import { CustomEditor } from '$app/components/editor/command';
import { EditorMarkFormat, EditorNodeType } from '$app/application/document/document.types';
import isEqual from 'lodash-es/isEqual';

export const withMarkdown = (editor: ReactEditor) => {
  const { insertText } = editor;

  editor.insertText = (char) => {
    const { selection } = editor;

    insertText(char);
    if (!selection || !Range.isCollapsed(selection)) {
      return;
    }

    const triggerShortcuts = whatShortcutTrigger(char);

    if (!triggerShortcuts) {
      return;
    }

    const match = CustomEditor.getBlock(editor);
    const [node, path] = match as NodeEntry<Element>;

    let prevIsNumberedList = false;

    try {
      const prevPath = Path.previous(path);
      const prev = editor.node(prevPath) as NodeEntry<Element>;

      prevIsNumberedList = prev && prev[0].type === EditorNodeType.NumberedListBlock;
    } catch (e) {
      // do nothing
    }

    const start = Editor.start(editor, path);
    const beforeRange = { anchor: start, focus: selection.anchor };
    const beforeText = Editor.string(editor, beforeRange);

    const removeBeforeText = (beforeRange: Range) => {
      editor.deleteBackward('character');
      editor.delete({
        at: beforeRange,
      });
    };

    const matchBlockShortcuts = whatShortcutsMatch(beforeText);

    for (const shortcut of matchBlockShortcuts) {
      const block = whichBlock(shortcut, beforeText);

      // if the block shortcut is matched, remove the before text and turn to the block
      // then return
      if (block && defaultTriggerChar[shortcut].includes(char)) {
        // Don't turn to the block condition
        // 1. Heading should be able to co-exist with number list
        if (block.type === EditorNodeType.NumberedListBlock && node.type === EditorNodeType.HeadingBlock) {
          return;
        }

        // 2. If the block is the same type, and data is the same
        if (block.type === node.type && isEqual(block.data || {}, node.data || {})) {
          return;
        }

        // 3. If the block is number list, and the previous block is also number list
        if (block.type === EditorNodeType.NumberedListBlock && prevIsNumberedList) {
          return;
        }

        removeBeforeText(beforeRange);
        CustomEditor.turnToBlock(editor, block);

        return;
      }
    }

    // get the range that matches the mark shortcuts
    const markRange = {
      anchor: Editor.start(editor, selection.anchor.path),
      focus: selection.focus,
    };
    const rangeText = Editor.string(editor, markRange) + char;

    if (!rangeText) return;

    // inputting a character that is start of a mark
    const isStartTyping = rangeText.indexOf(char) === rangeText.lastIndexOf(char);

    if (isStartTyping) return;

    // if the range text includes a double character mark, and the last one is not finished
    const doubleCharNotFinish =
      ['*', '_', '~'].includes(char) &&
      rangeText.indexOf(`${char}${char}`) > -1 &&
      rangeText.indexOf(`${char}${char}`) === rangeText.lastIndexOf(`${char}${char}`);

    if (doubleCharNotFinish) return;

    const matchMarkShortcuts = whatShortcutsMatch(rangeText);

    for (const shortcut of matchMarkShortcuts) {
      const item = getRegex(shortcut).find((p) => p.pattern.test(rangeText));
      const execArr = item?.pattern?.exec(rangeText);

      const removeText = execArr ? execArr[0] : '';

      const text = execArr ? execArr[2]?.replaceAll(char, '') : '';

      if (text) {
        const index = rangeText.indexOf(removeText);
        const removeRange = {
          anchor: {
            path: markRange.anchor.path,
            offset: markRange.anchor.offset + index,
          },
          focus: {
            path: markRange.anchor.path,
            offset: markRange.anchor.offset + index + removeText.length,
          },
        };

        removeBeforeText(removeRange);
        insertMark(editor, shortcut, text);
        return;
      }
    }
  };

  return editor;
};

function whichBlock(shortcut: MarkdownShortcuts, beforeText: string) {
  switch (shortcut) {
    case MarkdownShortcuts.Heading:
      return {
        type: EditorNodeType.HeadingBlock,
        data: {
          level: beforeText.length,
        },
      };
    case MarkdownShortcuts.CodeBlock:
      return {
        type: EditorNodeType.CodeBlock,
        data: {
          language: 'json',
        },
      };
    case MarkdownShortcuts.BulletedList:
      return {
        type: EditorNodeType.BulletedListBlock,
        data: {},
      };
    case MarkdownShortcuts.NumberedList:
      return {
        type: EditorNodeType.NumberedListBlock,
        data: {
          number: Number(beforeText.split('.')[0]) ?? 1,
        },
      };
    case MarkdownShortcuts.TodoList:
      return {
        type: EditorNodeType.TodoListBlock,
        data: {
          checked: beforeText.includes('[x]'),
        },
      };
    case MarkdownShortcuts.BlockQuote:
      return {
        type: EditorNodeType.QuoteBlock,
        data: {},
      };
    case MarkdownShortcuts.Divider:
      return {
        type: EditorNodeType.DividerBlock,
        data: {},
      };

    case MarkdownShortcuts.ToggleList:
      return {
        type: EditorNodeType.ToggleListBlock,
        data: {
          collapsed: false,
        },
      };

    default:
      return null;
  }
}

function insertMark(editor: ReactEditor, shortcut: MarkdownShortcuts, text: string) {
  switch (shortcut) {
    case MarkdownShortcuts.Bold:
    case MarkdownShortcuts.Italic:
    case MarkdownShortcuts.StrikeThrough:
    case MarkdownShortcuts.Code: {
      const textNode = {
        text,
      };
      const attributes = {
        [MarkdownShortcuts.Bold]: {
          [EditorMarkFormat.Bold]: true,
        },
        [MarkdownShortcuts.Italic]: {
          [EditorMarkFormat.Italic]: true,
        },
        [MarkdownShortcuts.StrikeThrough]: {
          [EditorMarkFormat.StrikeThrough]: true,
        },
        [MarkdownShortcuts.Code]: {
          [EditorMarkFormat.Code]: true,
        },
      };

      Object.assign(textNode, attributes[shortcut]);

      editor.insertNodes(textNode);
      return;
    }

    case MarkdownShortcuts.Equation: {
      CustomEditor.insertFormula(editor, text);
      return;
    }

    default:
      return null;
  }
}
