import { TextAction } from '$app/interfaces/document';
import { Keyboard } from '$app/constants/document/keyboard';
import { ReactEditor } from 'slate-react';
import { Editor, Range } from 'slate';
import { converToSlatePoint } from '$app/utils/document/slate_editor';
import { EQUATION_PLACEHOLDER } from '$app/constants/document/name';

const bold = {
  type: TextAction.Bold,
  /**
   * ** or __
   */
  markdownRegexp: /(\*\*|__)([^\s](?:[^\s]*?[^\s])?)(\*\*|__)$/,
};
const italic = {
  type: TextAction.Italic,
  /**
   * * or _
   */
  markdownRegexp: /(\*|_)([^\s](?:[^\s]*?[^\s])?)(\*|_)$/,
};
const strikethrough = {
  type: TextAction.Strikethrough,

  /**
   * ~~
   */
  markdownRegexp: /(~~)([^\s](?:[^\s]*?[^\s])?)(~~)$/,
};
const inlineCode = {
  type: TextAction.Code,
  /**
   * `
   */
  markdownRegexp: /(`)([^\s](?:[^\s]*?[^\s])?)(`)$/,
};
const inlineEquation = {
  type: TextAction.Equation,
  /**
   * $
   */
  markdownRegexp: /(\$)([^\s](?:[^\s]*?[^\s])?)(\$)$/,
};
const config: Record<
  string,
  {
    type: TextAction;
    getValue?: (matchStr: string) => string | boolean;
    markdownRegexp: RegExp;
  }[]
> = {
  [Keyboard.keys.ASTERISK]: [bold, italic],
  [Keyboard.keys.UNDER_SCORE]: [bold, italic],
  [Keyboard.keys.TILDE]: [strikethrough],
  [Keyboard.keys.BACK_QUOTE]: [inlineCode],
  [Keyboard.keys.DOLLAR]: [inlineEquation],
};

export const withMarkdown = (editor: ReactEditor) => {
  const { insertText } = editor;

  editor.insertText = (text) => {
    const { selection } = editor;
    const char = text.charAt(text.length - 1);
    const matchFormatTypes = config[char];

    if (matchFormatTypes && matchFormatTypes.length > 0 && selection && Range.isCollapsed(selection)) {
      const { anchor } = selection;
      const start = Editor.start(editor, []);
      const range = { anchor, focus: start };
      const textString = Editor.string(editor, range) + text;
      const prevChar = textString.charAt(textString.length - 2);

      // If the previous character is a space, we don't want to trigger the markdown
      if (prevChar === ' ') {
        return insertText(text);
      }

      for (const formatType of matchFormatTypes) {
        const match = textString.match(formatType.markdownRegexp);

        if (match) {
          const pluralStart = match[0].substring(0, 2) === char.padStart(2, char);
          const pluralEnd = prevChar === char;

          if (pluralStart && !pluralEnd) {
            break;
          }

          const matchIndex = match.index || 0;

          if (formatType.type === TextAction.Equation) {
            formatEquation(editor, matchIndex, match[2]);
            return;
          }

          // format already applied
          editor.select({
            anchor,
            focus: converToSlatePoint(editor, matchIndex),
          });
          if (isMarkAction(editor, formatType.type)) {
            editor.select(anchor);
            break;
          }

          Editor.addMark(editor, formatType.type, true);

          // delete extra characters
          editor.select(converToSlatePoint(editor, matchIndex));
          editor.delete({
            distance: pluralStart ? 2 : 1,
          });

          editor.select(converToSlatePoint(editor, matchIndex + match[2].length));
          if (pluralStart) {
            editor.delete({
              distance: 1,
            });
          }

          return;
        }
      }
    }

    insertText(text);
  };

  return editor;
};

function isMarkAction(editor: Editor, format: string) {
  const marks = Editor.marks(editor) as Record<string, boolean> | null;

  return marks ? !!marks[format] : false;
}

function formatEquation(editor: Editor, index: number, latex: string) {
  editor.select(converToSlatePoint(editor, index));
  editor.delete({
    distance: latex.length + 1,
  });

  editor.insertNode(
    {
      text: EQUATION_PLACEHOLDER,
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      formula: latex,
    },
    {
      select: true,
    }
  );
}
