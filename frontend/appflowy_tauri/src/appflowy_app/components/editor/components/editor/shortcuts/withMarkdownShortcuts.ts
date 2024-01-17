import { ReactEditor } from 'slate-react';
import { Editor, Range, Element as SlateElement, Transforms } from 'slate';
import { EditorMarkFormat, EditorNodeType } from '$app/application/document/document.types';
import { CustomEditor } from '$app/components/editor/command';

const regexMap: Record<
  string,
  {
    pattern: RegExp;
    data?: Record<string, unknown>;
  }[]
> = {
  [EditorNodeType.BulletedListBlock]: [
    {
      pattern: /^(\*|-|\+)$/,
    },
  ],
  [EditorNodeType.ToggleListBlock]: [
    {
      pattern: /^>$/,
      data: {
        collapsed: false,
      },
    },
  ],
  [EditorNodeType.QuoteBlock]: [
    {
      pattern: /^”$/,
    },
    {
      pattern: /^“$/,
    },
    {
      pattern: /^"$/,
    },
  ],
  [EditorNodeType.TodoListBlock]: [
    {
      pattern: /^\[ \]$/,
      data: {
        checked: false,
      },
    },
    {
      pattern: /^\[x\]$/,
      data: {
        checked: true,
      },
    },
    {
      pattern: /^\[\]$/,
      data: {
        checked: false,
      },
    },
  ],
  [EditorNodeType.NumberedListBlock]: [
    {
      pattern: /^(\d+)\.$/,
    },
  ],
  [EditorNodeType.HeadingBlock]: [
    {
      pattern: /^#{1}$/,
      data: {
        level: 1,
      },
    },
    {
      pattern: /^#{2}$/,
      data: {
        level: 2,
      },
    },
    {
      pattern: /^#{3}$/,
      data: {
        level: 3,
      },
    },
  ],
  [EditorNodeType.CodeBlock]: [
    {
      pattern: /^```$/,
      data: {
        language: 'javascript',
      },
    },
  ],
  [EditorNodeType.CalloutBlock]: [
    {
      pattern: /^(\[!)(TIP|INFO|WARNING|DANGER)(\])$/,
    },
  ],
  [EditorNodeType.DividerBlock]: [
    {
      pattern: /^(-{3,})$/,
    },
  ],
  [EditorNodeType.EquationBlock]: [
    {
      pattern: /^(\${2})(\s)*(.+)(\s)*(\${2})$/,
    },
  ],
};

const CharToMarkTypeMap: Record<string, EditorMarkFormat> = {
  '**': EditorMarkFormat.Bold,
  __: EditorMarkFormat.Bold,
  '*': EditorMarkFormat.Italic,
  _: EditorMarkFormat.Italic,
  '~': EditorMarkFormat.StrikeThrough,
  '~~': EditorMarkFormat.StrikeThrough,
  '`': EditorMarkFormat.Code,
};

const matchShortcutType = (beforeText: string, endChar: string) => {
  if (endChar === '-') {
    const dividerRegex = regexMap[EditorNodeType.DividerBlock][0];

    return dividerRegex.pattern.test(beforeText + endChar)
      ? {
          type: EditorNodeType.DividerBlock,
          data: {},
        }
      : null;
  }

  for (const [type, regexes] of Object.entries(regexMap)) {
    for (const regex of regexes) {
      if (regex.pattern.test(beforeText)) {
        return {
          type,
          data: regex.data,
        };
      }
    }
  }

  return null;
};

export const withMarkdownShortcuts = (editor: ReactEditor) => {
  const { insertText } = editor;

  editor.insertText = (text) => {
    if (CustomEditor.isCodeBlock(editor) || CustomEditor.selectionIncludeRoot(editor)) {
      insertText(text);
      return;
    }

    const { selection } = editor;

    if (!selection || !Range.isCollapsed(selection)) {
      insertText(text);
      return;
    }

    // end with inline mark char: * or _ or ~ or `
    // eg: **bold** or *italic* or ~strikethrough~ or `code` or _italic_ or __bold__ or ~~strikethrough~~
    const keyword = ['*', '_', '~', '`'].find((char) => text.endsWith(char));

    if (keyword !== undefined) {
      const { focus } = selection;
      const start = {
        path: focus.path,
        offset: 0,
      };
      const range = { anchor: start, focus };

      const rangeText = Editor.string(editor, range);

      if (!rangeText.includes(keyword)) {
        insertText(text);
        return;
      }

      const fullText = rangeText + keyword;

      let matchChar = keyword;

      if (['*', '_', '~'].includes(keyword)) {
        const doubleKeyword = `${keyword}${keyword}`;

        if (rangeText.includes(doubleKeyword)) {
          const match = fullText.match(new RegExp(`\\${keyword}{2}(.*)\\${keyword}{2}`));

          if (!match) {
            insertText(text);
            return;
          }

          matchChar = doubleKeyword;
        }
      }

      const markType = CharToMarkTypeMap[matchChar];

      const startIndex = rangeText.lastIndexOf(matchChar);
      const beforeText = rangeText.slice(startIndex + matchChar.length, matchChar.length > 1 ? -1 : undefined);

      if (!beforeText) {
        insertText(text);
        return;
      }

      const anchor = { path: start.path, offset: start.offset + startIndex };

      const at = {
        anchor,
        focus,
      };

      editor.select(at);
      editor.addMark(markType, true);
      editor.insertText(beforeText);
      editor.collapse({
        edge: 'end',
      });
      return;
    }

    // end with space
    if (text.endsWith(' ') || text.endsWith('-')) {
      const endChar = text.slice(-1);
      const [match] = Editor.nodes(editor, {
        match: (n) => !Editor.isEditor(n) && SlateElement.isElement(n) && n.type === EditorNodeType.Text,
      });

      if (!match) {
        insertText(text);
        return;
      }

      const [, path] = match;

      const { anchor } = selection;
      const start = Editor.start(editor, path);
      const range = { anchor, focus: start };
      const beforeText = Editor.string(editor, range) + text.slice(0, -1);

      if (beforeText === undefined) {
        insertText(text);
        return;
      }

      const matchItem = matchShortcutType(beforeText, endChar);

      if (matchItem) {
        const { type, data } = matchItem;

        Transforms.select(editor, range);

        if (!Range.isCollapsed(range)) {
          Transforms.delete(editor);
        }

        const newProperties: Partial<SlateElement> = {
          type,
          data,
        };

        CustomEditor.turnToBlock(editor, newProperties);

        return;
      }
    }

    insertText(text);
  };

  return editor;
};
