import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { getBlock, getBlockEntry, getSharedRoot, getText } from '@/application/slate-yjs/utils/yjsOperations';
import {
  BlockType,
  HeadingBlockData,
  NumberedListBlockData,
  TodoListBlockData,
  ToggleListBlockData,
  YjsEditorKey,
} from '@/application/types';
import { Editor, Range, Transforms } from 'slate';

type TriggerHotKey = {
  [key in BlockType | EditorMarkFormat]?: string[];
};

const defaultTriggerChar: TriggerHotKey = {
  [BlockType.HeadingBlock]: [' '],
  [BlockType.QuoteBlock]: [' '],
  [BlockType.CodeBlock]: ['`'],
  [BlockType.BulletedListBlock]: [' '],
  [BlockType.NumberedListBlock]: [' '],
  [BlockType.TodoListBlock]: [' '],
  [BlockType.ToggleListBlock]: [' '],
  [BlockType.DividerBlock]: ['-', '*'],
  [EditorMarkFormat.Bold]: ['*', '_'],
  [EditorMarkFormat.Italic]: ['*', '_'],
  [EditorMarkFormat.StrikeThrough]: ['~'],
  [EditorMarkFormat.Code]: ['`'],
  [EditorMarkFormat.Formula]: ['$'],
};

// create a set of all trigger characters
export const allTriggerChars = new Set(Object.values(defaultTriggerChar).flat());

// Define the rules for markdown shortcuts
type Rule = {
  type: 'block' | 'mark'
  match: RegExp
  format: string
  transform?: (editor: YjsEditor, match: RegExpMatchArray) => void
  filter?: (editor: YjsEditor, match: RegExpMatchArray) => boolean
}

function deletePrefix (editor: YjsEditor, offset: number) {
  const [, path] = getBlockEntry(editor);

  const { selection } = editor;

  if (!selection) return;
  editor.select({
    anchor: editor.start(path),
    focus: { path: selection.focus.path, offset: offset },
  });
  editor.delete();
}

function getNodeType (editor: YjsEditor) {
  const [node] = getBlockEntry(editor);

  return node.type as BlockType;
}

function getBlockData (editor: YjsEditor) {
  const [node] = getBlockEntry(editor);

  return node.data;
}

function isEmptyLine (editor: YjsEditor, offset: number) {
  const [node] = getBlockEntry(editor);
  const sharedRoot = getSharedRoot(editor);
  const block = getBlock(node.blockId as string, sharedRoot);
  const yText = getText(block.get(YjsEditorKey.block_external_id), sharedRoot);

  return yText.toJSON().length === offset;
}

const rules: Rule[] = [
  // Blocks
  {
    type: 'block',
    match: /^(#{1,6})\s/,
    format: BlockType.HeadingBlock,
    filter: (editor, match) => {
      const level = match[1].length;
      const blockType = getNodeType(editor);
      const blockData = getBlockData(editor);

      return blockType === BlockType.HeadingBlock && (blockData as HeadingBlockData).level === level;
    },
    transform: (editor, match) => {
      const level = match[1].length;
      const [node] = getBlockEntry(editor);

      deletePrefix(editor, level);
      CustomEditor.turnToBlock<HeadingBlockData>(editor, node.blockId as string, BlockType.HeadingBlock, { level });
    },
  },
  {
    type: 'block',
    match: /^"\s/,
    format: BlockType.QuoteBlock,
    filter: (editor) => {
      return getNodeType(editor) === BlockType.QuoteBlock;
    },
    transform: (editor) => {
      deletePrefix(editor, 1);
      CustomEditor.turnToBlock(editor, getBlockEntry(editor)[0].blockId as string, BlockType.QuoteBlock, {});
    },
  },
  {
    type: 'block',
    match: /^(-)?\[(x| )?\]\s/,
    format: BlockType.TodoListBlock,
    filter: (editor, match) => {
      const checked = match[2] === 'x';
      const blockType = getNodeType(editor);
      const blockData = getBlockData(editor);

      return blockType === BlockType.TodoListBlock && (blockData as TodoListBlockData).checked === checked;
    },
    transform: (editor, match) => {
      deletePrefix(editor, match[0].length - 1);
      const checked = match[2] === 'x';

      CustomEditor.turnToBlock<TodoListBlockData>(editor, getBlockEntry(editor)[0].blockId as string, BlockType.TodoListBlock, { checked });
    },
  },
  {
    type: 'block',
    match: /^>\s/,
    format: BlockType.ToggleListBlock,
    filter: (editor) => {
      return getNodeType(editor) === BlockType.ToggleListBlock;
    },
    transform: (editor) => {
      deletePrefix(editor, 1);
      CustomEditor.turnToBlock<ToggleListBlockData>(editor, getBlockEntry(editor)[0].blockId as string, BlockType.ToggleListBlock, { collapsed: false });
    },
  },
  {
    type: 'block',
    match: /^(`){3,}$/,
    format: BlockType.CodeBlock,
    filter: (editor) => {
      return !isEmptyLine(editor, 2) || getNodeType(editor) === BlockType.CodeBlock;
    },
    transform: (editor) => {
      deletePrefix(editor, 2);

      CustomEditor.turnToBlock(editor, getBlockEntry(editor)[0].blockId as string, BlockType.CodeBlock, {});
    },
  },
  {
    type: 'block',
    match: /^(-|\*|\+)\s/,
    format: BlockType.BulletedListBlock,
    filter: (editor) => {
      return getNodeType(editor) === BlockType.BulletedListBlock;
    },
    transform: (editor) => {
      deletePrefix(editor, 1);
      CustomEditor.turnToBlock(editor, getBlockEntry(editor)[0].blockId as string, BlockType.BulletedListBlock, {});
    },
  },
  {
    type: 'block',
    match: /^(\d+)\.\s/,
    format: BlockType.NumberedListBlock,
    filter: (editor, match) => {
      const start = parseInt(match[1]);
      const blockType = getNodeType(editor);
      const blockData = getBlockData(editor);

      return blockType === BlockType.HeadingBlock || (blockType === BlockType.NumberedListBlock && (blockData as NumberedListBlockData).number === start);
    },
    transform: (editor, match) => {
      const start = parseInt(match[1]);

      deletePrefix(editor, String(start).length + 1);
      CustomEditor.turnToBlock<NumberedListBlockData>(editor, getBlockEntry(editor)[0].blockId as string, BlockType.NumberedListBlock, { number: start });
    },
  },

  {
    type: 'block',
    match: /^([-*_]){3,}$/,
    format: BlockType.DividerBlock,
    filter: (editor) => {
      return !isEmptyLine(editor, 2) || getNodeType(editor) === BlockType.DividerBlock;
    },
    transform: (editor) => {
      deletePrefix(editor, 2);
      CustomEditor.turnToBlock(editor, getBlockEntry(editor)[0].blockId as string, BlockType.DividerBlock, {});
    },
  },

  // marks
  {
    type: 'mark',
    match: /\*\*(.*?)\*\*|__(.*?)__/,
    format: EditorMarkFormat.Bold,
  },
  {
    type: 'mark',
    match: /\*(.*?)\*|_(.*?)_/,
    format: EditorMarkFormat.Italic,
    filter: (_editor, match) => {
      const key = match[0];

      if (key === '**') return true;
      const text = match[1] || match[2];

      return !text || text.length === 0;
    },
  },
  {
    type: 'mark',
    match: /~~(.*?)~~/,
    format: EditorMarkFormat.StrikeThrough,
  },
  {
    type: 'mark',
    match: /`(.*?)`/,
    format: EditorMarkFormat.Code,
    filter: (_editor, match) => {
      const text = match[1];

      return text.length === 0;
    },
  },
  {
    type: 'mark',
    match: /\$(.*?)\$/,
    format: EditorMarkFormat.Formula,
    transform: (editor, match) => {
      const formula = match[1];
      const { selection } = editor;

      if (!selection) return;
      const path = selection.anchor.path;
      const start = match.index!;

      editor.insertText('$');
      Transforms.select(editor, {
        anchor: { path, offset: start },
        focus: { path, offset: start + 1 },
      });

      CustomEditor.addMark(editor, { key: EditorMarkFormat.Formula, value: formula });
    },
  },
];

export const applyMarkdown = (editor: YjsEditor, insertText: string): boolean => {
  const { selection } = editor;

  if (!selection || !Range.isCollapsed(selection)) return false;

  const [, path] = getBlockEntry(editor);
  const start = Editor.start(editor, path);
  const text = editor.string({
    anchor: start,
    focus: selection.focus,
  }) + insertText;

  for (const rule of rules) {
    if (rule.type === 'block') {
      const match = text.match(rule.match);

      if (match && !rule.filter?.(editor, match)) {

        if (rule.transform) {
          rule.transform(editor, match);
        }

        return true;
      }
    } else if (rule.type === 'mark') {
      const path = selection.anchor.path;
      const text = editor.string({
        anchor: {
          path,
          offset: 0,
        },
        focus: selection.focus,
      }) + insertText;

      const matches = [...text.matchAll(new RegExp(rule.match, 'g'))];

      if (matches.length > 0 && matches.every((match) => !rule.filter?.(editor, match))) {
        for (const match of matches.reverse()) {
          const start = match.index!;
          const end = start + match[0].length - 1;
          const matchRange = {
            anchor: { path, offset: start },
            focus: { path, offset: end },
          };

          Transforms.select(editor, matchRange);
          editor.delete();

          if (rule.transform) {
            rule.transform(editor, match);
          } else {
            const formatText = match[1] || match[2];

            editor.insertText(formatText);
            Transforms.select(editor, {
              anchor: { path, offset: start },
              focus: { path, offset: start + formatText.length },
            });

            CustomEditor.addMark(editor, { key: rule.format as EditorMarkFormat, value: true });
          }

          Transforms.collapse(editor, { edge: 'end' });

        }

        return true;
      }

    }
  }

  return false;
};